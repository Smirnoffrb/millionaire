require 'rails_helper'

RSpec.feature 'USER views another user', type: :feature do
  let(:user) { FactoryBot.create(:user, name: 'Михаил') }

  let(:game1) do
    FactoryBot.create(
      :game,
      user: user,
      current_level: 8,
      prize: 8000,
      created_at: '23 июля, 22:20')
  end

  let(:game2) do
    FactoryBot.create(
      :game,
      user: user,
      current_level: 12,
      prize: 32000,
      is_failed: true,
      fifty_fifty_used: true,
      created_at: '23 июля, 22:30',
      finished_at: '23 июля, 22:40'
    )
  end

  let!(:games) { [game1, game2] }

  before do
    visit '/'
    click_link 'Михаил'
  end

  feature 'unregistered user views another user' do
    scenario 'gets required url' do
      expect(page).to have_current_path '/users/1'
    end

    scenario 'gets name of user' do
      expect(page).to have_content 'Михаил'
    end

    scenario 'does not change name and password' do
      expect(page).not_to have_content 'Сменить имя и пароль'
    end

    feature 'game1' do
      scenario 'gets time game1' do
        expect(page).to have_content '23 июля, 22:20'
      end

      scenario 'gets number of question' do
        expect(page).to have_content(game1.current_level)
      end

      scenario 'gets prize' do
        expect(page).to have_content '2 000 ₽'
      end

      scenario 'is in progress' do
        expect(page).to have_content 'в процессе'
      end
    end

    feature 'game2' do
      scenario 'gets time game2' do
        expect(page).to have_content '23 июля, 22:30'
      end

      scenario 'gets number of question' do
        expect(page).to have_content(game2.current_level)
      end

      scenario 'gets 50/50 hint' do
        expect(page).to have_content '50/50'
      end

      scenario 'is failed' do
        expect(page).to have_content 'проигрыш'
      end

      scenario 'gets prize' do
        expect(page).to have_content '32 000 ₽'
      end
    end
  end
end
