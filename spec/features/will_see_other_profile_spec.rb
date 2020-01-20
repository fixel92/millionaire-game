require 'rails_helper'

RSpec.feature 'USER will see alien profile', type: :feature do
  let!(:user1) { FactoryBot.create(:user, id: 1, name: 'Петя') }
  let!(:user2) { FactoryBot.create(:user, id: 2, name: 'Коля') }

  before(:each) do
    (1..5).each do |i|
      FactoryBot.create(
          :game, id: i + 80,
          created_at: Time.parse("2016.10.0#{i}, 13:30"),
          finished_at: Time.parse("2016.10.0#{i}, 13:37"),
          current_level: 10 + i,
          prize: 20000 + i * 1000,
          user: user2
      )
    end
  end

  scenario 'success' do
    login_as user1
    visit '/'

    click_link 'Коля'

    expect(page).to have_content('Коля')
    expect(page).to have_content('деньги', count: 4)
    expect(page).to have_content('победа')
    expect(page).not_to have_content('Сменить имя и пароль')
    expect(page).to have_link(href: '/users/1')
    expect(page).to have_content('Петя - 0 ₽')

    (1..5).to_a.each do |i|
      expect(page).to have_content("8#{i}")
      expect(page).to have_content("1#{i}")
      expect(page).to have_content("2#{i}")
      expect(page).to have_content("0#{i} окт., 13:30")
    end
  end
end
