# (c) goodprogrammer.ru

# Стандартный rspec-овский помощник для rails-проекта
require 'rails_helper'

# Наш собственный класс с вспомогательными методами
require 'support/my_spec_helper'

# Тестовый сценарий для модели Игры
#
# В идеале — все методы должны быть покрыты тестами, в этом классе содержится
# ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # Пользователь для создания игр
  let(:user) { FactoryBot.create(:user) }

  # Игра с прописанными игровыми вопросами
  let(:game_w_questions) do
    FactoryBot.create(:game_with_questions, user: user)
  end

  let(:question) { game_w_questions.current_game_question }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # Генерим 60 вопросов с 4х запасом по полю level, чтобы проверить работу
      # RANDOM при создании игры.
      generate_questions(60)

      game = nil

      # Создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
        # Проверка: Game.count изменился на 1 (создали в базе 1 игру)
      }.to change(Game, :count).by(1).and(
        # GameQuestion.count +15
        change(GameQuestion, :count).by(15).and(
          # Game.count не должен измениться
          change(Question, :count).by(0)
        )
      )

      # Проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      # Проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # Тесты на основную игровую логику
  context 'game mechanics' do
    # Правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # Текущий уровень игры и статус
      level = game_w_questions.current_level
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(question.correct_answer_key)

      # Перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)

      # Ранее текущий вопрос стал предыдущим
      expect(game_w_questions.current_game_question).not_to eq(question)

      # Игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it '#take_money! correct' do
      game_w_questions.answer_current_question!(question.correct_answer_key)
      game_w_questions.take_money!
      prize = game_w_questions.prize

      expect(prize).to be > 0
      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize
    end
  end

  context 'game status' do
    it '#status in_progress' do
    game_w_questions.answer_current_question!(question.correct_answer_key)

    expect(game_w_questions.status).to eq(:in_progress)
    end

    it '#status won' do
      game_w_questions.answer_current_question!(question.correct_answer_key)
      game_w_questions.take_money!

      expect(game_w_questions.status).to eq :money
    end

    it '#status won' do
      15.times do
        game_w_questions.answer_current_question!(question.correct_answer_key)
      end

      expect(game_w_questions.status).to eq :won
    end

    it '#status timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.answer_current_question!(question.correct_answer_key)

      expect(game_w_questions.status).to eq :timeout
    end

    it '#status fail' do
      answers = question.variants
      answers.delete(question.correct_answer_key)

      game_w_questions.answer_current_question!(answers.keys.sample)

      expect(game_w_questions.status).to eq :fail
    end
  end

  describe '#current_game_question' do
    context 'number question match GameQuestion id' do
      it 'returns i' do
        (1..15).each do |i|
          game_w_questions.current_level = "#{i - 1}"
          expect(game_w_questions.current_game_question.id).to eq i
        end
      end
    end
  end

  describe '#previous_level' do
    context 'second question' do
      it 'returns 1' do
        game_w_questions.current_level = '2'
        expect(game_w_questions.previous_level).to eq 1
      end
    end
    context 'last question' do
      it 'returns 13' do
        game_w_questions.current_level = '14'
        expect(game_w_questions.previous_level).to eq 13
      end
    end
  end

  describe '#answer_current_question!' do
    context 'right answer' do
      it 'returns true' do
        expect(game_w_questions.answer_current_question!(question.correct_answer_key)).to be true
      end
      it 'returns status in_progress' do
        game_w_questions.answer_current_question!(question.correct_answer_key)
        expect(game_w_questions.status).to eq :in_progress
      end

      it 'returns finished_at not nil' do
        game_w_questions.answer_current_question!(question.correct_answer_key)
        expect(game_w_questions.finished?).to be false
      end
    end

    context 'wrong answer' do
      let(:answers) { question.variants }
      before(:each) { answers.delete(question.correct_answer_key) }

      it 'returns false' do
        expect(game_w_questions.answer_current_question!(answers.keys.sample)).to be false
      end

      it 'returns status fail' do
        game_w_questions.answer_current_question!(answers.keys.sample)
        expect(game_w_questions.status).to eq :fail
      end

      it 'returns finished? true' do
        game_w_questions.answer_current_question!(answers.keys.sample)
        expect(game_w_questions.finished?).to be true
      end
    end

    context 'last answer to million' do
      before(:each) { game_w_questions.current_level = '14' }
      it 'return true' do
        expect(game_w_questions.answer_current_question!(question.correct_answer_key)).to be true
      end

      it 'returns status won' do
        game_w_questions.answer_current_question!(question.correct_answer_key)
        expect(game_w_questions.status).to eq :won
      end

      it 'returns finished? true' do
        game_w_questions.answer_current_question!(question.correct_answer_key)
        expect(game_w_questions.finished?).to be true
      end
    end

    context 'answer after timeout' do
      before(:each) { game_w_questions.created_at = 1.hour.ago }
      it 'return status time_out after right answer' do

        game_w_questions.answer_current_question!(question.correct_answer_key)

        expect(game_w_questions.status).to eq :timeout
      end

      it 'return status time_out after wrong answer' do
        answers = question.variants
        answers.delete(question.correct_answer_key)

        game_w_questions.answer_current_question!(answers.keys.sample)
        expect(game_w_questions.status).to eq :timeout
      end

      it 'returns finished? true' do
        game_w_questions.answer_current_question!(question.correct_answer_key)
        expect(game_w_questions.finished?).to be true
      end
    end
  end
end
