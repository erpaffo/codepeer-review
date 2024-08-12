import * as ActiveStorage from '@rails/activestorage';
import 'channels';
import $ from 'jquery';
import Turbolinks from "turbolinks";
import Rails from "@rails/ujs"

Rails.start()

Turbolinks.start();

ActiveStorage.start();

global.$ = jQuery;