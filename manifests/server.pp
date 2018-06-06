# class to manage the actual prometheus server
# this is a private class that gets called from the init.pp
class prometheus::server (
  String $configname,
  String $user,
  String $group,
  Array $extra_groups,
  Stdlib::Absolutepath $bin_dir,
  Stdlib::Absolutepath $shared_dir,
  String $version,
  String $install_method,
  Variant[Stdlib::HTTPUrl, Stdlib::HTTPSUrl] $download_url_base,
  String $download_extension,
  String $package_name,
  String $package_ensure,
  String $config_dir,
  Stdlib::Absolutepath $localstorage,
  String $config_template,
  String $config_mode,
  Hash $global_config,
  Array $rule_files,
  Array $scrape_configs,
  Array $remote_read_configs,
  Array $remote_write_configs,
  Variant[Array,Hash] $alerts,
  Array $alert_relabel_config,
  Array $alertmanagers_config,
  String $storage_retention,
  Stdlib::Absolutepath $env_file_path,
  Hash $extra_alerts,
  Boolean $service_enable,
  String $service_ensure,
  Boolean $manage_service,
  Boolean $restart_on_change,
  String $init_style,
  String $extra_options,
  Hash $config_hash,
  Hash $config_defaults,
  Optional[String] $download_url,
  Boolean $manage_group,
  Boolean $purge_config_dir,
  Boolean $manage_user,
  String $os = downcase($facts['kernel']),
) {

  include prometheus
  $arch = $prometheus::real_arch

  if( versioncmp($version, '1.0.0') == -1 ){
    $real_download_url = pick($download_url,
      "${download_url_base}/download/${version}/${package_name}-${version}.${os}-${arch}.${download_extension}")
  } else {
    $real_download_url = pick($download_url,
      "${download_url_base}/download/v${version}/${package_name}-${version}.${os}-${arch}.${download_extension}")
  }
  $notify_service = $restart_on_change ? {
    true    => Service['prometheus'],
    default => undef,
  }

  $config_hash_real = assert_type(Hash, deep_merge($config_defaults, $config_hash))

  file { "${config_dir}/rules":
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => $config_mode,
  }

  $extra_alerts.each | String $alerts_file_name, Hash $alerts_config | {
    prometheus::alerts { $alerts_file_name:
      alerts   => $alerts_config,
    }
  }
  $extra_rule_files = suffix(prefix(keys($extra_alerts), "${config_dir}/rules/"), '.rules')

  if ! empty($alerts) {
    prometheus::alerts { 'alert':
      alerts   => $alerts,
      location => $config_dir,
    }
    $_rule_files = concat(["${config_dir}/alert.rules"], $extra_rule_files)
  }
  else {
    $_rule_files = $extra_rule_files
  }
  contain prometheus::install
  contain prometheus::config
  contain prometheus::run_service
  contain prometheus::service_reload

  Class['prometheus::install']
  -> Class['prometheus::config']
  -> Class['prometheus::run_service']
  -> Class['prometheus::service_reload']
}
