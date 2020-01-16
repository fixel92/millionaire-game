require 'rails_helper'

RSpec.describe 'users/index', type: :view do
  before(:each) do
    assign(:users, [
        FactoryBot.build_stubbed(:user, name: 'Петя', balance: 5000),
        FactoryBot.build_stubbed(:user, name: 'Маша', balance: 3000)
    ])

    render
  end

  it 'renders player names' do
    expect(rendered).to match 'Петя'
    expect(rendered).to match 'Маша'
  end

  it 'renders player balances' do
    expect(rendered).to match '5 000 ₽'
    expect(rendered).to match '3 000 ₽'
  end

  it 'renders player names in right order' do
    expect(rendered).to match /Петя.*Маша/m
  end
end