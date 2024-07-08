import Rails from '@rails/ujs';
import Turbolinks from "turbolinks"
import * as ActiveStorage from '@rails/activestorage';
import 'channels';
import 'jquery';
import 'bootstrap';

Rails.start()
ActiveStorage.start()


console.log("Javascript loaded!")