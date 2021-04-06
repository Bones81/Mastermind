module Boards
  class Board
    def initialize
      @guesses = Array.new(12) { |elt| Array.new(4, "") }
      @results = []
      @color_options = ["blue", "pink", "green", "yellow", "orange"]
      @correct_peg = "red" 
      @partial_peg = "white"
    end

    attr_accessor :guesses, :results
    attr_reader :color_options, :correct_peg, :partial_peg

    def display(game)
      puts "\n-------Guesses-------|-----Feedback-----|"
      i = 0
      while i <= game.turns_taken do
        puts "#{i + 1}. #{guesses[i].join(" ")} | #{results[i].join(" ")}"
        i += 1
      end
      puts "-----------------------------------------\n"
    end
  end
end

module Players
  class Player
    include Boards

    def initialize
    end

  end

  class Human < Player
    def initialize(name)
      @name = name
    end

    attr_reader :name

    def create_code(board, game)
      get_entry(board, game)
    end

    def get_entry(board, game)
      game.codemaker.class.name.split('::').last == "Human" ? entry_type = "code" : entry_type = "guess"
      puts "\nPlease enter your #{entry_type} by typing in four (4) colors, separated by a single space each. \n\nBe sure your spelling is correct.\n\n"
      puts "The order of colors in your #{entry_type} matters. \n\nYou may repeat colors within your #{entry_type}, but no blanks are allowed.\n\n" 
      puts "(Example entry: blue blue yellow green)\n\n" 
      puts "Available colors = #{board.color_options}\n\n"
      print "Your #{entry_type}: "
      entry = gets.chomp.downcase.split(" ")

      unless valid_input?(entry, board)
        puts "\n`````````````````````````````````````"
        puts "You have entered an invalid response.\n"
        puts "Please type in four (4) choices only for your #{entry_type}, and use only the listed color options.\n"
        puts "`````````````````````````````````````\n"
        print "(Press ENTER/RETURN key to continue.)\n\n"
        gets
        get_entry(board, game)
      else
        return entry
      end
    end

    private

    def valid_input?(input, board) 
      input.length == 4 && input.all? { |value| 
        board.color_options.include?(value) 
      }
    end
  end

  class Computer < Player
    def initialize(board)
      @name = "the computer"
      @temp_correct = 0
      @temp_partial_correct = 0
      @potential_solutions = board.color_options.repeated_permutation(4).to_a
    end

    attr_reader :name
    attr_accessor :temp_correct, :temp_partial_correct, :potential_solutions

    def create_code(board, game)
      code = Array.new(4) {|e| board.color_options.sample}
      code # returns randomly generated code
    end

    def get_entry(board, game)  
      initial_entry = [board.color_options[0], board.color_options[0], board.color_options[1], board.color_options[1]]
      if game.turns_taken == 0
        entry = initial_entry
      else
        entry = generate_next_guess(board, game)
        return entry
      end
    end

    def generate_next_guess(board, game)
      prev_results = board.results[game.turns_taken - 1]
      prev_guess = board.guesses[game.turns_taken - 1]
      
      @potential_solutions.each do |option|
        
        compare_prev_guess_to_temp_code(prev_guess, option)
        # print option.join(" ")
        if generate_temp_feedback(board) != prev_results
          @potential_solutions -= [option]
        end 
        # Somehow, the above command is sometimes eliminating options that should not be eliminated, occasionally resulting in zero options remaining when that shouldn't be the case.
      end

      # @potential_solutions.each do |option|
      #   puts option.join(" ")
      # end # Checking for accuracy of variable

      puts "Generating a computer guess..."
      return @potential_solutions.sample # for now, just return a random remaining option
    end

    def compare_prev_guess_to_temp_code(guess, temp_code)
      @temp_correct = num_temp_correct(guess, temp_code)
      @temp_partial_correct = num_temp_partial_correct(guess, temp_code) 
    end

    def generate_temp_feedback(board)
      temp_feedback = []
      @temp_correct.times do 
        temp_feedback.push(board.correct_peg)
      end

      @temp_partial_correct.times do
        temp_feedback.push(board.partial_peg)
      end
      # puts ": #{temp_feedback.join(" ")}."
      temp_feedback
    end

    def num_temp_correct(temp_guess, temp_code)
      result = 0
      temp_guess.each_index do |idx|
        if temp_guess[idx] == temp_code[idx] 
          result += 1
        end
      end
      result
    end

    def num_temp_partial_correct(temp_guess, temp_code)
      result = 0
      temp_guess_checks_noted = []
      temp_code_checks_noted = []

      temp_guess.each_index do |idx|
        if temp_guess[idx] == temp_code[idx]  
          temp_guess_checks_noted[idx] = "checked"
          temp_code_checks_noted[idx] = "checked"
        else
          temp_guess_checks_noted[idx] = temp_guess[idx]
          temp_code_checks_noted[idx] = temp_code[idx]
        end  
      end

      temp_guess_checks_noted.each do |value|
        if value == "checked"
          next
        elsif temp_code_checks_noted.include?(value)
          result += 1
          temp_code_checks_noted[temp_code_checks_noted.index(value)] = "checked"
        end     
      end

      result
    end

  end
end

class Game
  include Players
  include Boards

  def initialize
    @game_board = Board.new
    print "Please enter your name: "
    @human_player = Human.new(gets.chomp)
    @computer_player = Computer.new(@game_board)
    @codemaker = nil
    @codebreaker = nil
    @turns_taken = 0
    @code = nil
    @code_broken = false
    @correct = 0
    @partial_correct = 0
  end

  attr_accessor :human_player, :computer_player, :game_board, :codemaker, :codebreaker, :turns_taken, :code, :code_broken, :correct, :partial_correct

  def run
    start_game
    turn_sequence(self)
  end

  private
  def start_game
    display_intro
    set_roles
    @code = codemaker.create_code(game_board, self)
    puts "\n~~~~~~~~~~~~~~~~~~~~\n#{codemaker.name.capitalize} has decided on a code! Can #{codebreaker.name} break it?!?\n~~~~~~~~~~~~~~~~~~~~~~"
  end

  def display_intro
    puts "\n\nWelcome to Mastermind!" 
    puts "~~~~~~~~~~~~~~~~~~~~~~"
    puts "\nMastermind involves a game board and two players -- one human-controlled and one computer-controlled. \n\nOne player (the codemaker) sets a secret code. The code has 4 slots which can be filled with one of #{game_board.color_options.length} color options. \n\nThe codemaker may place the same color in more than one slot. \n\nThe other player (the codebreaker) has 12 opportunities to guess the secret code. \n\nThe codebreaker must guess both the colors and the order in which they appear in the secret code. \n\nAfter each guess, the codebreaker will receive feedback indicating: \n1) how many elements of the guess were correct in both color and location and \n2) how many elements of the guess were correct in color but wrong in location. \n\nThe codebreaker wins by guessing the code correctly within 12 guesses. \n\nThe codebreaker loses if 12 guesses occur without breaking the code.\n\nGot it? Let's play!\n\n"
  end

  def set_roles
    print "#{human_player.name}, would you like to be (1) the codebreaker or (2) the codemaker? (Enter 1 or 2): " 
    answer = gets.chomp.to_i
    if answer == 1
      @codebreaker = @human_player
      @codemaker = @computer_player
    elsif answer == 2
      @codemaker = @human_player
      @codebreaker = @computer_player
    else 
      input_error_message
      set_roles
    end
  end

  def input_error_message
    puts "You have entered an invalid response.\n\n"
  end

  def turn_sequence(game)
    guess = codebreaker.get_entry(game_board, game)
    game_board.guesses[turns_taken] = guess
    
    compare_guess_to_code(guess)

    display_feedback_key
    generate_feedback

    game_board.display(game)

    if codebreaker == @computer_player && @code_broken == false
      puts "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      print "(Press ENTER/RETURN key to continue.)\n"
      gets
    end

    if game_over?
      play_again? ? start_new_game : exit_game  
    else
      puts "The codebreaker has taken #{turns_taken} turns and has #{12 - turns_taken} remaining.\n"
      turn_sequence(game)
    end
  end

  def compare_guess_to_code(guess)
    if guess == @code 
      @code_broken = true
    end
    @correct = num_fully_correct(guess)
    @partial_correct = num_partial_correct(guess)    
  end

  def num_fully_correct(guess)
    result = 0
    guess.each_index do |idx|
      if guess[idx] == @code[idx] 
        result += 1
      end
    end
    result
  end

  def num_partial_correct(guess)
    result = 0
    guess_checks_noted = []
    code_checks_noted = []

    guess.each_index do |idx|
      if guess[idx] == @code[idx]  
        guess_checks_noted[idx] = "checked"
        code_checks_noted[idx] = "checked"
      else
        guess_checks_noted[idx] = guess[idx]
        code_checks_noted[idx] = @code[idx]
      end   
    end

    guess_checks_noted.each do |value|
      if value == "checked"
        next
      elsif code_checks_noted.include?(value)
        result += 1
        code_checks_noted[code_checks_noted.index(value)] = "checked"
      end     
    end
    result
  end

  def display_feedback_key
    puts "\n---Feedback Key--"
    puts "Correct color and correct position = #{game_board.correct_peg}"
    puts "Correct color in wrong position = #{game_board.partial_peg}"
    puts "-----------------\n"
  end

  def generate_feedback
    feedback = []
    @correct.times do 
      feedback.push(game_board.correct_peg)
    end
    @partial_correct.times do
      feedback.push(game_board.partial_peg)
    end
    game_board.results[turns_taken] = feedback
  end

  def game_over?
    win? || loss? ? true : false
  end

  def win?
    if @code_broken == true
      if codebreaker == @human_player
       puts "\nCongratulations! You broke the code!\n\n"
      else 
       puts "\n#{@computer_player.name.capitalize} has broken your code!\n\n"
      end
      true
    else
     @turns_taken += 1
     false
    end
  end

  def loss?
    if @turns_taken == 12
      if codebreaker == @human_player
        puts "\nNo guesses remaining. You lose. :(\n"
      else
        puts "\n#{@computer_player.name.capitalize} has run out of guesses. You win! :)\n"
      end
      puts "\nThe code was #{@code.join(" ")}.\n"
      true
    else
      false
    end
  end

  def play_again?
    print "Play again? (Press \"y\" for yes or \"n\" for no.): "
    choice = gets.chomp.downcase
    choice == "y" ? true : false
  end

  def start_new_game
    puts ""
    new_game = Game.new
    new_game.run
  end

  def exit_game
    puts "\nThanks for playing!"
    exit
  end

  
end

game = Game.new
game.run