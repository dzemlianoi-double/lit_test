# frozen_string_literal: true

require 'yaml'

def show_menu(promocode:, name: 'гість')
  puts "Привіт, #{name}"
  puts "Promocode: #{promocode[:name_promocode]}" unless promocode.nil?
  puts 'Вітаємо в піцерії'
  puts 'Трошки гірше, ніж у мами!'
  puts 'Оберіть дію та введіть її номер:'
  puts "1. Назвіть нам своє ім'я"
  puts '2. Введіть промокод'
  puts '3. Меню піц'
  puts '4. Зробити замовлення'
  puts '5. Вийти'
end

def ask_name(name:)
  puts 'Як вас звати? (back - у головне меню)'
  new_name = gets.chomp
  if new_name == 'back'
    name = 'гість'
  else
    puts "Ваше ім'я зареєстроване #{new_name}"
    new_name
  end
end

def handle_input(input:, name:, promocode:)
  if input == '1'
    name = ask_name(name:)
  elsif input == '2'
    promocode = ask_promocode(promocode:)
  elsif input == '3'
    show_pizza_menu
  elsif input == '4'
    ask_order(promocode:)
  elsif input == '5'
    exit
  end
  run(name:, promocode:)
end

def list_of_promocods
  YAML.safe_load(File.read('promocodes.yml'), permitted_classes: [Symbol, String, Hash]) || []
end

def ask_promocode(promocode:)
  puts 'Введіть промокод (back - у головне меню): '
  new_promocode = gets.chomp

  return promocode if new_promocode == 'back'

  promocodes_list = list_of_promocods
  found_promocodes = promocodes_list.detect do |promo|
    new_promocode.upcase == promo[:name_promocode].upcase
  end

  return nil if found_promocodes.nil?

  puts "Promocode: #{found_promocodes[:name_promocode]}"
  puts "Discount -#{found_promocodes[:absolute_discount]}UAH" if found_promocodes[:absolute_discount] != 0
  puts "Discount -#{found_promocodes[:percentage_discount]}%" if found_promocodes[:percentage_discount] != 0

  found_promocodes
end

def list_of_menu
  YAML.safe_load(File.read('menu.yml'), permitted_classes: [Hash, String, Symbol]) || []
end

def show_pizza_menu
  list_of_menu.each do |user|
    puts "#{user[:name_of_pizza]} || #{user[:phrase_pizza]}"
    puts "#{user[:price]} грн || #{user[:weigth]} г || #{user[:pieces_of_pizza]}"
    puts "#{user[:ingredients]}"
  end
end

def find_pizza(name)
  list_of_menu.detect { |kind_of_pizza| name == kind_of_pizza[:name_of_pizza] }
end

def request_pizza
  puts 'back - у меню; чернетку замовлення буде скасовано.'
  puts 'Введіть слаг піцци, будь-ласка: '
  pizza_name = gets.chomp

  return nil if ['next', 'back'].include?(pizza_name)

  found_pizza = find_pizza(pizza_name)

  return nil if found_pizza.nil?

  puts "Скільки піц #{found_pizza[:name_of_pizza]}"

  count_of_pizza = gets.chomp

  { pizza: found_pizza, count: count_of_pizza.to_i }
end

def guests_count
  puts 'Скільки гостей їстимуть піцу? Скажіть будь-ласка'
  puts 'Вкажіть число від 0 до 8, включно із собою.'
  puts '0 - замовлення на виніс.'

  guests = gets.chomp.to_i
  guests = 1 if guests == 0

  guests
end

def has_cheese_sides?
  puts 'Додати сирні бортики до кожної піци?'
  puts 'Це +10: до вартості піц. (так/ні/не знаю)'

  gets.chomp.upcase == 'ТАК'
end

def calculate_discount(promocode:, total_price:)
  return 0 if promocode.nil?

  if promocode[:absolute_discount].positive?
    if total_price - promocode[:absolute_discount].to_i > 0
      promocode[:absolute_discount].to_i
    else
      total_price
    end
  end

  if promocode[:percentage_discount].positive?
    total_price.to_i * promocode[:percentage_discount].to_f / 100
  end
end

def print_check(promocode:, ordered_pizzas: ,has_cheese_sides:, guests_count:)
  base_price = calculate_base_price
  total_pizza_count = ordered_pizzas.map do |pizza_order|
    pizza_order[:count]
  end.sum
  total_slices_count = ordered_pizzas.map do |pizza_order|
    pizza_order[:count] * pizza_order[:pizza][:pieces_of_pizza]
  end.sum

  total_weight = ordered_pizzas.map do |pizza_order|
    pizza_order[:count] * pizza_order[:pizza][:weigth]
  end.sum

  cheese_slides_price = if has_cheese_sides == true
    base_price * 0.1 
  else
    0
  end

  total_price_without_discount = base_price + cheese_slides_price
  discount = calculate_discount(total_price: total_price_without_discount, promocode:)

  final_amount = total_price_without_discount.to_i - discount.to_i

  promocode_name = if promocode.nil?
    '-'
  else
    promocode[:name_promocode]
  end

  puts 'Дякуємо за замовлення, Кіберкіт!'
  puts 'Трошки гірше, ніж у мами'

  puts 'Піци: '
  puts "Бортики, +10: +#{cheese_slides_price}"
  puts "Промокод #{promocode_name}: -#{discount}"
  puts "ДО СПЛАТИ: #{final_amount}"

  puts "Піц: #{total_pizza_count}"
  puts "Шматочків: #{total_slices_count}"
  puts "Вага за меню: #{total_weight} г"
  puts "Гостей: #{guests_count}"
  puts "На людину: #{total_slices_count / guests_count} шматочків і #{total_weight / guests_count} г"

  puts 'Смачного! Якщо мама запитає - ви їли суп.'
end

def ask_order(promocode:)
  ordered_pizzas = []

  loop do
    pizza = request_pizza

    break if pizza.nil?

    ordered_pizzas.push(pizza)
  end

  return nil if ordered_pizzas == []

  guests = guests_count
  has_cheese_sides = has_cheese_sides?

  puts 'Готуємо ваш чек...'

  print_check(promocode:, ordered_pizzas:,has_cheese_sides:, guests_count: guests)
end

def run(name: nil, promocode: nil)
  show_menu(name:, promocode:)
  user_input = gets.chomp
  handle_input(input: user_input, name:, promocode:)
  run(name:, promocode:)
end

run
