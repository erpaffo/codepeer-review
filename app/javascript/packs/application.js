import * as ActiveStorage from '@rails/activestorage';
import 'channels';
import $ from 'jquery';
import Turbolinks from "turbolinks";
Turbolinks.start();

ActiveStorage.start();

global.$ = jQuery;