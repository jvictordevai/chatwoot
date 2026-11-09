require 'rails_helper'

describe Cca::Branding do
  describe '.apply!' do
    it 'overwrites existing Chatwoot branding with the Community defaults' do
      InstallationConfig.where(name: described_class::KEYS).delete_all
      InstallationConfig.create!(name: 'INSTALLATION_NAME', value: 'Chatwoot')
      InstallationConfig.create!(name: 'BRAND_URL', value: 'https://www.chatwoot.com')

      described_class.apply!

      expect(InstallationConfig.find_by(name: 'INSTALLATION_NAME').value).to eq('Community')
      expect(InstallationConfig.find_by(name: 'BRAND_NAME').value).to eq('Community')
      expect(InstallationConfig.find_by(name: 'BRAND_URL').value).to eq('https://communityca.com.br')
      expect(InstallationConfig.find_by(name: 'LOGO').value).to eq('/brand-assets/logo.svg')
    end

    it 'covers every branding key and refreshes the global config cache' do
      allow(GlobalConfig).to receive(:clear_cache)

      described_class.apply!

      expect(InstallationConfig.where(name: described_class::KEYS).count).to eq(described_class::KEYS.size)
      expect(GlobalConfig).to have_received(:clear_cache).at_least(:once)
    end
  end
end
