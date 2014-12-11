class puppet_tags (
  $gitrepo,
  $minversion = '0.0.0',
) {

  File {
    ensure  => file,
    owner   => 'root',
    group   => 'root',
  }

  file {
    '/usr/bin/puppet_tags.rb':
      source  => 'puppet:///modules/puppet_tags/puppet_tags.rb',
      mode    => '0744';

    '/etc/puppet_tags.yaml':
      content => template('puppet_tags/puppet_tags.yaml.erb'),
      mode    => '0644';
  }
    
}
