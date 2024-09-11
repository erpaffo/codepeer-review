import { Controller } from "@hotwired/stimulus";
import consumer from "../channels/consumer";

export default class extends Controller {
  static values = { chatRoomId: Number }

  connect() {
    this.channel = consumer.subscriptions.create(
      { channel: "MessagesChannel", conversation_id: this.chatRoomIdValue },
      {
        received: (data) => {
          this.appendMessage(data);
        }
      }
    );
  }

  disconnect() {
    this.channel.unsubscribe();
  }

  sendMessage(event) {
    event.preventDefault();
    const input = this.element.querySelector('input[type="text"]');
    const message = input.value;
    input.value = "";

    this.channel.perform("send_message", { message: message, conversation_id: this.chatRoomIdValue });
  }

  appendMessage(data) {
    const messageContainer = this.element.querySelector('#messages');
    const messageElement = document.createElement('p');
    messageElement.textContent = `${data.user}: ${data.body}`;
    messageContainer.appendChild(messageElement);
  }
}
