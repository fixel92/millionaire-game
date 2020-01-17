require 'rails_helper'

RSpec.describe 'users/show', type: :view do

  describe 'show info user' do
    let!(:user) { FactoryBot.build_stubbed(:user, name: 'Петя', balance: 5000) }
    let!(:game_1) { FactoryBot.build_stubbed(:game, id: 15,
                                             created_at: Time.parse('2016.10.09, 13:00'),
                                             finished_at: Time.parse('2016.10.09, 13:15'),
                                             current_level: 10, prize: 10000) }

    let!(:game_2) { FactoryBot.build_stubbed(:game, id: 16,
                                             created_at: Time.parse('2016.10.09, 14:00'),
                                             finished_at: Time.parse('2016.10.09, 14:15'),
                                             current_level: 5, prize: 5000) }


    before(:each) do
      assign(:user, user)
      assign(:games, [game_1, game_2])

      render
    end

    context 'anonym user' do
      it 'renders player name' do
        expect(rendered).to match 'Петя'
      end

      it 'renders game ids' do
        expect(rendered).to match '15'
        expect(rendered).to match '16'
      end

      it 'renders games statuses' do
        expect(rendered).to match 'деньги'
      end

      it 'renders game_question levels ' do
        expect(rendered).to match '10'
        expect(rendered).to match '5'
      end

      it 'renders time games' do
        expect(rendered).to match '09 окт., 13:00'
        expect(rendered).to match '09 окт., 14:00'
      end

      it 'renders level games' do
        expect(rendered).to match '10'
        expect(rendered).to match '5'
      end

      it 'renders price games' do
        expect(rendered).to match '10 000 ₽'
        expect(rendered).to match '5 000 ₽'
      end
    end

    context 'auth user' do
      let!(:user) { FactoryBot.create(:user) }

      before(:each) do
        sign_in user

        render
      end

      it 'renders player name' do
        expect(rendered).to match /Жора_*/
      end

      it 'renders button change password' do
        expect(rendered).to match 'Сменить имя и пароль'
      end
    end
  end
end
