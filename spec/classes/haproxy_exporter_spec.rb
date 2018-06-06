require 'spec_helper'

describe 'prometheus::haproxy_exporter' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(os_specific_facts(facts))
      end
      let(:pre_condition) do
        'include prometheus'
      end

      context 'with version specified' do
        let(:params) do
          {
            version: '0.7.1',
            arch: 'amd64',
            os: 'linux',
            bin_dir: '/usr/local/bin',
            install_method: 'url'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/usr/local/bin/haproxy_exporter').with('target' => '/opt/haproxy_exporter-0.7.1.linux-amd64/haproxy_exporter') }
        it { is_expected.to contain_archive('/tmp/haproxy_exporter-0.7.1.tar.gz') }
        it { is_expected.to contain_class('prometheus') }
        it { is_expected.to contain_user('haproxy-user') }
        it { is_expected.to contain_group('haproxy-exporter') }
        it { is_expected.to contain_prometheus__daemon('haproxy_exporter') }
      end
    end
  end
end
