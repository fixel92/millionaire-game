require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  describe '#show' do
    context 'anonym user' do
      it 'kick from #show Game' do
        get :show, id: game_w_questions.id

        expect(response.status).not_to eq 200
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end

    context 'auth user' do
      before(:each) { sign_in user }

      it '#show Game success' do
        get :show, id: game_w_questions.id
        game = assigns(:game)

        expect(game.finished?).to be_falsey
        expect(game.user).to eq(user)
        expect(response.status).to eq 200
        expect(response).to render_template('show')
      end

      it 'answer correct' do
        generate_questions(60)
        put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key

        game = assigns(:game)

        expect(game.finished?).to be_falsey
        expect(game.current_level).to be > 0
        expect(response).to redirect_to(game_path(game))
        expect(flash.empty?).to be_truthy
      end

      it 'answer wrong' do
        generate_questions(60)
        answer = game_w_questions.current_game_question.variants
        answer.delete(game_w_questions.current_game_question.correct_answer_key)

        put :answer, id: game_w_questions.id, letter: answer

        game = assigns(:game)

        expect(game.finished?).to be_truthy
        expect(response).to redirect_to(user_path(user))
        expect(flash[:alert]).to be
      end

      context 'user doesnt see other game' do
        it 'redirect to root_path and flash notice' do
          alien_game = FactoryBot.create(:game_with_questions)
          get :show, id: alien_game.id

          expect(response).to redirect_to(root_path)
          expect(response.status).to eq 302
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#take_money' do
    context 'user takes money after 2 right answers' do
      it 'returns user profile and warning' do
        sign_in user
        game_w_questions.update_attribute(:current_level, 2)

        put :take_money, id: game_w_questions.id
        game = assigns(:game)

        expect(game.finished?).to be_truthy
        expect(game.prize).to eq 200

        user.reload

        expect(user.balance).to eq 200
        expect(response.status).to eq 302
        expect(response).to redirect_to(user_path(user))
        expect(flash[:warning]).to be
      end
    end

    context 'user anonym' do
      it 'returns user profile and warning' do
        game_w_questions.update_attribute(:current_level, 2)

        put :take_money, id: game_w_questions.id
        game = assigns(:game)

        expect(response.status).to eq 302
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#create' do
    context 'auth user' do
      before(:each) { sign_in user }
      before(:each) { generate_questions(60) }

      it 'games #create' do
        post :create
        game = assigns(:game)

        expect(game.finished?).to be_falsey
        expect(game.user).to eq(user)
        expect(response).to redirect_to game_path(game)
        expect(flash[:notice]).to be
      end

      it 'redirect user on first game if he wants create second game' do
        expect(game_w_questions.finished?).to be_falsey
        expect { post :create }.to change(Game, :count).by(0)

        game = assigns(:game)

        expect(game).to be_nil
        expect(response).to redirect_to game_path(game_w_questions)
        expect(flash[:alert]).to be
      end
    end

    context 'anonym user' do
      it 'redirect to user auth' do
        post :create
        game = assigns(:game)

        expect(game).to be_nil
        expect(response.status).to eq 302
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#answer' do
    context 'anonym user' do
      it 'redirect to user_path' do
        generate_questions(60)
        put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
        game = assigns(:game)

        expect(game).to be_nil
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to be
      end
    end
  end

  describe 'audience help' do
    context 'auth user' do
      before(:each) { sign_in user }

      it 'used help and redirect' do
        expect(game_w_questions.current_game_question.help_hash[:audience_help]).not_to be
        expect(game_w_questions.audience_help_used).to be_falsey

        put :help, id: game_w_questions.id, help_type: :audience_help
        game = assigns(:game)

        expect(game.finished?).to be_falsey
        expect(game.audience_help_used).to be_truthy
        expect(game.current_game_question.help_hash[:audience_help]).to be
        expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c' ,'d')
        expect(response).to redirect_to game_path(game)
      end

    end
  end
end
