<?php 
return array (
  0 => 
  array (
    'name' => 'test',
    'logo' => NULL,
    'skin' => './css/pawtunes-dark.css',
    'streams' => 
    array (
      'Default Quality' => 
      array (
        'mp3' => 'https://hirschmilch.de:7000/progressive.mp3',
      ),
    ),
    'stats' => 
    array (
      'method' => 'direct',
      'url' => 'https://hirschmilch.de:7000/progressive.mp3',
      'fallback' => '',
    ),
  ),
  1 => 
  array (
    'name' => 'regea',
    'logo' => NULL,
    'skin' => './css/pawtunes-dark.css',
    'streams' => 
    array (
      'Default Quality' => 
      array (
        'mp3' => 'http://strm112.1.fm/reggae_mobile_mp3',
      ),
    ),
    'stats' => 
    array (
      'method' => 'direct',
      'url' => 'http://strm112.1.fm/reggae_mobile_mp3',
      'fallback' => '',
    ),
  ),
  2 => 
  array (
    'name' => 'Jazz',
    'logo' => NULL,
    'skin' => './css/pawtunes.css',
    'streams' => 
    array (
      'Default Quality' => 
      array (
        'mp3' => 'https://icecast.walmradio.com:8443/jazz',
      ),
    ),
    'stats' => 
    array (
      'method' => 'icecast-public',
      'url' => 'https://icecast.walmradio.com:8443/',
      'mount' => '',
    ),
  ),
);
