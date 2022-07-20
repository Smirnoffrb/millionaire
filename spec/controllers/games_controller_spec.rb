require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, is_admin: true) }
  let(:game_w_questions) { create(:game_with_questions, user: user) }

  describe '#show' do
    context 'when user anonymous' do
      it 'kick from show' do
        get :show, id: game_w_questions.id

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'when user logged in' do
      before { sign_in user } # логиним юзера users с помощью спец. Devise метода sign_in

      it 'show the game' do
        get :show, id: game_w_questions.id
        game = assigns(:game) # вытаскиваем из контроллера поле @game
        expect(game.finished?).to be false
        expect(game.user).to eq(user)

        expect(response.status).to eq(200)
        expect(response).to render_template('show')
      end

      it 'show alien game' do
        alien_game = create(:game_with_questions)
        get :show, id: alien_game.id

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#create' do
    context 'when user anonymous' do
      it 'kick from create' do
        post :create

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'when user logged in' do
      before { sign_in user }

      it 'create game' do
        # сперва накидаем вопросов, из чего собирать новую игру
        generate_questions(15)

        post :create
        game = assigns(:game) # вытаскиваем из контроллера поле @game

        expect(game.finished?).to be false
        expect(game.user).to eq(user)
        # и редирект на страницу этой игры
        expect(response).to redirect_to(game_path(game))
        expect(flash[:notice]).to be
      end

      it 'try to create second game' do
        expect(game_w_questions.finished?).to be_falsey
        expect { post :create }.to change(Game, :count).by(0)

        game = assigns(:game)
        expect(game).to be_nil

        expect(response).to redirect_to(game_path(game_w_questions))
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#answer' do
    context 'when user anonymous' do
      before { get :show, id: game_w_questions.id }

      it 'response' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'show alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when user logged in' do
      before { sign_in user }

      context 'correct answer' do
        let(:game) { assigns(:game) }

        before do
          put :answer, id: game_w_questions.id,
              letter: game_w_questions.current_game_question.correct_answer_key
        end

        it 'not finish the game' do
          expect(game.finished?).to be false
        end

        it 'get to next level' do
          expect(game.current_level).to be > 0
        end

        it 'redirect' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'not show flash' do
          expect(flash.empty?).to be true
        end
      end

      context 'wrong answer' do
        before {
          put :answer, id: game_w_questions.id,
              letter: (%w(a b c d) - [game_w_questions.current_game_question.correct_answer_key]).sample
        }

        let(:game) { assigns(:game) }

        it 'game finished' do
          expect(game.finished?).to be true
        end

        it 'redirect to the profile page' do
          expect(response).to redirect_to(user_path(user))
        end

        it 'flash has an alert' do
          expect(flash[:alert]).to be
        end

        it 'the game is lost' do
          expect(game.status).to eq(:fail)
        end
      end

      context 'audience help' do
        it 'uses audience help' do
          # сперва проверяем что в подсказках текущего вопроса пусто
          expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
          expect(game_w_questions.audience_help_used).to be_falsey

          # фигачим запрос в контроллен с нужным типом
          put :help, id: game_w_questions.id, help_type: :audience_help
          game = assigns(:game)

          # проверяем, что игра не закончилась, что флажок установился, и подсказка записалась
          expect(game.finished?).to be_falsey
          expect(game.audience_help_used).to be_truthy
          expect(game.current_game_question.help_hash[:audience_help]).to be
          expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
          expect(response).to redirect_to(game_path(game))
        end
      end


    end
  end

  describe '#take_money' do
    context 'when user anonymous' do

      it 'kick from take_money' do
        put :take_money, id: game_w_questions.id

        expect(response.status).not_to eq(200)
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'when user logged in' do
      before { sign_in user }

      it 'takes money' do
        game_w_questions.update_attribute(:current_level, 2)
        put :take_money, id: game_w_questions.id
        game = assigns(:game)

        expect(game.finished?).to be true
        expect(game.prize).to eq(200)

        user.reload
        expect(user.balance).to eq(200)

        expect(response).to redirect_to(user_path(user))
        expect(flash[:warning]).to be
      end
    end
  end

  describe '#help' do
    before do
      sign_in user
    end

    context 'fifty-fifty help' do
      context 'when help not used' do
        before do
          expect(game_w_questions.current_game_question.help_hash[:fifty_fifty]).not_to be
          expect(game_w_questions.fifty_fifty_used).to be false

          put :help, id: game_w_questions.id, help_type: :fifty_fifty
        end

        let!(:game) { assigns(:game) }

        it 'use fifty-fifty help' do
          expect(game.fifty_fifty_used).to be true
        end

        it 'add fifty-fifty help to help hash' do
          expect(game.current_game_question.help_hash).to include(:fifty_fifty)
        end

        it 'add fifry-fifty help to array of 2 elements' do
          expect(game.current_game_question.help_hash[:fifty_fifty].size).to eq 2
        end

        it 'adds fifty-fifty help with correct answer key' do
          correct_answer_key = game.current_game_question.correct_answer_key
          expect(game.current_game_question.help_hash[:fifty_fifty]).to include(correct_answer_key)
        end
      end

      context 'when help already used' do
        before do
          game_w_questions.fifty_fifty_used = true
          game_w_questions.save

          put :help, id: game_w_questions.id, help_type: :fifty_fifty
        end

        let!(:game) { assigns(:game) }

        it 'flash alert' do
          expect(flash[:alert]).to be
        end

        it 'redirect to game path' do
          expect(response).to redirect_to(game_path(game))
        end
      end
    end
  end
 end
