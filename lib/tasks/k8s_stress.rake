namespace :k8s do
  desc 'Run Kubernetes stress tests with parallel Jobs (requires K8S_ENABLED=true and kubectl)'
  task :stress, [:parallel, :timeout, :cpu, :mem] => :environment do |_t, args|
    unless Rails.configuration.x.k8s.enabled
      puts 'K8S is not enabled. Set K8S_ENABLED=true'
      next
    end

    parallel = (args[:parallel] || ENV['PARALLEL'] || 5).to_i
    timeout  = (args[:timeout]  || ENV['TIMEOUT']  || 300).to_i
    cpu      = args[:cpu] || ENV['CPU'] || '1'
    mem      = args[:mem] || ENV['MEM'] || '1Gi'

    workloads = [
      { name: 'cpu-stress', image: 'alpine:3.20', command: ['sh', '-lc', 'apk add --no-cache stress-ng && stress-ng --cpu 2 --timeout 60s'] },
      { name: 'tf-cpu',     image: 'tensorflow/tensorflow:2.16.1', command: ['python', '-c', 'import tensorflow as tf; m=tf.keras.Sequential([tf.keras.layers.Dense(512, activation="relu"), tf.keras.layers.Dense(10)]); m.compile(optimizer="adam", loss="sparse_categorical_crossentropy"); import numpy as np; x=np.random.rand(10000,1000); y=np.random.randint(10,size=(10000,)); m.fit(x,y,epochs=1,verbose=2)'] },
      { name: 'torch-cpu',  image: 'pytorch/pytorch:2.3.1-cpu', command: ['python', '-c', 'import torch; import torch.nn as nn; m=nn.Sequential(nn.Linear(1000,512), nn.ReLU(), nn.Linear(512,10)); x=torch.randn(10000,1000); y=torch.randint(0,10,(10000,)); loss=nn.CrossEntropyLoss(); opt=torch.optim.Adam(m.parameters());
for i in range(50):
  opt.zero_grad();
  o=m(x);
  l=loss(o, y);
  l.backward();
  opt.step();
print("done")'] }
    ]

    started = []
    threads = []
    parallel.times do |i|
      threads << Thread.new(i) do |idx|
        wl = workloads[idx % workloads.size]
        begin
          puts "Starting job #{idx+1}/#{parallel} -> #{wl[:name]}"
          out, err, st = Kube::RawJobRunner.run(
            image: wl[:image],
            command: wl[:command],
            timeout_s: timeout,
            cpu_limit: cpu,
            memory_limit: mem,
            name_prefix: "stress-#{wl[:name]}"
          )
          started << { index: idx+1, name: wl[:name], out: out, err: err, ok: st.success? }
          puts "Job #{idx+1} finished ok=#{st.success?}"
        rescue => e
          started << { index: idx+1, name: wl[:name], out: '', err: e.message, ok: false }
          puts "Job #{idx+1} failed to start: #{e.message}"
        end
      end
    end
    threads.each(&:join)

    ok = started.count { |s| s[:ok] }
    failc = started.size - ok
    puts "Summary: #{ok} succeeded, #{failc} failed"
    started.each do |s|
      puts "\n--- Job #{s[:index]} (#{s[:name]}) OK=#{s[:ok]} ---\nSTDOUT:\n#{s[:out]}\nSTDERR:\n#{s[:err]}\n"
    end
  end
end


