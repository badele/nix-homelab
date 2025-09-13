<?php 
return array (
  'tplOptions' => 
  array (
    'simple' => 
    array (
      'autoWindowResize' => false,
      'visualization' => true,
      'visualizationColor' => false,
    ),
  ),
  'artwork_sources' => 
  array (
    'itunes' => 
    array (
      'state' => 'enabled',
      'index' => 25,
    ),
    'spotify' => 
    array (
      'index' => 26,
      'api_key' => '',
    ),
    'fanarttv' => 
    array (
      'index' => 27,
      'api_key' => '',
    ),
    'lastfm' => 
    array (
      'index' => 28,
      'api_key' => '',
    ),
    'custom' => 
    array (
      'index' => 29,
      'api_url' => '',
    ),
  ),
  'title' => 'PawTunes',
  'description' => 'Discover PawTunes, the ultimate internet radio player with purrfect visuals, customizable templates, and clean code. Built for pros, loved by cats!',
  'site_title' => 'PawTunes Radio Player',
  'google_analytics' => '',
  'override_share_image' => '',
  'default_lang' => 'fr.php',
  'multi_lang' => true,
  'autoplay' => true,
  'debugging' => 'log-only',
  'default_channel' => 'regea',
  'default_volume' => '75',
  'template' => 'html5player',
  'artist_default' => 'Various Artists',
  'title_default' => 'Unknown Track',
  'dynamic_title' => true,
  'artist_maxlength' => '24',
  'title_maxlength' => '28',
  'stats_refresh' => '10',
  'track_regex' => '(?P<artist>[^-]*)[ ]?-[ ]?(?P<title>.*)',
  'history' => true,
  'cache_images' => true,
  'artist_images_only' => true,
  'artwork_lazy_loading' => true,
  'images_size' => '280',
  'admin_username' => 'admin',
  'admin_password' => '$2y$10$TI7WVV8ZiIktYvjYWzmCseW1/GqQ4oUq/YiRv7yXapHRmXNwz57bm',
  'cache' => 
  array (
    'path' => './data/cache',
  ),
);
