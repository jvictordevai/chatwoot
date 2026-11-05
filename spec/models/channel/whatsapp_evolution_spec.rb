require 'rails_helper'

RSpec.describe Channel::Whatsapp do
  describe 'whatsapp_evolution provider' do
    let(:channel) do
      create(:channel_whatsapp, provider: 'whatsapp_evolution', provider_config: { 'instance_name' => 'cw-1-1' },
                                sync_templates: false, validate_provider_config: false)
    end

    it 'uses the Evolution provider service' do
      expect(channel.provider_service).to be_a(Whatsapp::Providers::EvolutionService)
    end

    it 'does not sync Meta templates on create' do
      expect_any_instance_of(Whatsapp::Providers::EvolutionService).not_to receive(:sync_templates) # rubocop:disable RSpec/AnyInstance
      create(:channel_whatsapp, provider: 'whatsapp_evolution', provider_config: { 'instance_name' => 'cw-2' }, validate_provider_config: false)
    end

    it 'is invalid without an instance name' do
      channel = build(:channel_whatsapp, provider: 'whatsapp_evolution', provider_config: {})

      expect(channel).not_to be_valid
    end

    it 'hides the placeholder phone number until connected' do
      channel.update!(phone_number: described_class.evolution_placeholder_phone_number)
      expect(channel.evolution_connected_phone_number).to be_nil

      channel.update!(phone_number: '+5511912345678')
      expect(channel.evolution_connected_phone_number).to eq('+5511912345678')
    end

    it 'deletes the Evolution instance when destroyed' do
      service = instance_double(Evolution::InstanceService, delete!: true)
      allow(Evolution::InstanceService).to receive(:new).with(channel).and_return(service)

      with_modified_env(EVOLUTION_API_URL: 'http://evolution.test', EVOLUTION_API_KEY: 'key') { channel.destroy! }

      expect(service).to have_received(:delete!)
    end

    it 'has no 24h messaging window' do
      conversation = create(:conversation, inbox: channel.inbox)

      expect(conversation.can_reply?).to be(true)
    end
  end
end
