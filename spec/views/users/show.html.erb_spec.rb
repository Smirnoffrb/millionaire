require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  context 'when users on own page' do
    let(:current_user) { assign(:user, FactoryBot.build_stubbed(:user, name: 'Михаил')) }

    before do
      allow(view).to receive(:current_user).and_return(current_user)

      render
    end

    it 'renders change name and password' do
      expect(rendered).to match 'Сменить имя и пароль'
    end
  end

  context 'when users on other users page' do
    before do
      assign(:user, FactoryBot.build_stubbed(:user, name: 'Михаил'))

      render
    end

    it 'renders users name' do
      expect(rendered).to match 'Михаил'
    end

    it 'not render change name and password' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end

    it 'renders game partial' do
      assign(:games, [FactoryBot.build_stubbed(:game)])
      stub_template 'users/_game.html.erb' => 'User game goes here'

      render

      expect(rendered).to match 'User game goes here'
    end
  end
end
