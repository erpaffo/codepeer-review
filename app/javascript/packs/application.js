import Rails from '@rails/ujs';
import * as ActiveStorage from '@rails/activestorage';
import 'channels';
import $ from 'jquery';

Rails.start();
ActiveStorage.start();

global.$ = jQuery;