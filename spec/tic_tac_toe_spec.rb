require_relative '../tic_tac_toe'

# Only the winning and blocking moves are exhaustively tested.
describe TicTacToe do

  let(:ttt) { TicTacToe.new(:player_first) }
  let(:board) { ttt.instance_variable_get('@board') }

  {:winning => :computer_symbol, :blocking => :player_symbol}.each do |type, symbol|
    describe "#{type} moves" do
      it "should make a #{type} move if there are two #{symbol.to_s.sub('_', ' ')} in a row" do
        (0...3).each do |row|
          (0...3).each do |i|
            ((i + 1)...3).each do |j|
              ttt.restart
              board[row][i] = ttt.send(symbol)
              board[row][j] = ttt.send(symbol)
              remaining_index = ([0, 1, 2] - [i, j]).first

              expect {
                ttt.make_move
              }.to change { board[row][remaining_index] }.to(ttt.computer_symbol)
            end
          end
        end
      end

      it "should make a #{type} move if there are two #{symbol.to_s.sub('_', ' ')} in a column" do
        (0...3).each do |col|
          (0...3).each do |i|
            ((i + 1)...3).each do |j|
              ttt.restart
              board[i][col] = ttt.send(symbol)
              board[j][col] = ttt.send(symbol)
              remaining_index = ([0, 1, 2] - [i, j]).first

              expect {
                ttt.make_move
              }.to change { board[remaining_index][col] }.to(ttt.computer_symbol)
            end
          end
        end
      end

      {:forward => lambda { |x| x }, :backward => lambda { |x| 2 - x }}.each do |diagonal_type, offset|
        it "should make a #{type} move if there are two #{symbol.to_s.sub('_', ' ')} in a #{diagonal_type} diagonal" do
          (0...3).each do |i|
            ((i + 1)...3).each do |j|
              ttt.restart
              board[i][offset.call(i)] = ttt.send(symbol)
              board[j][offset.call(j)] = ttt.send(symbol)
              remaining_index = ([0, 1, 2] - [i, j]).first

              expect {
                ttt.make_move
              }.to change { board[remaining_index][offset.call(remaining_index)] }.to(ttt.computer_symbol)
            end
          end
        end
      end
    end
  end

  it 'should make a forking move if one is available' do
    ttt.restart
    board[0][1] = ttt.computer_symbol
    board[1][0] = ttt.computer_symbol

    expect {
      ttt.make_move
    }.to change { board[0][0] }.to(ttt.computer_symbol)
  end

  describe 'fork-blocking moves' do
    before do
      ttt.restart
    end

    it 'should directly block a potential player fork' do
      # .x.    ox.
      # x.. => x..
      # ...    ...
      board[0][1] = ttt.player_symbol
      board[1][0] = ttt.player_symbol

      expect {
        ttt.make_move
      }.to change { board[0][0] }.to(ttt.computer_symbol)
    end

    context 'when blocking a potential player fork would cause a player fork' do
      it 'should indirectly block the fork by creating two in a row to force the player to defend' do
        #  x..    xo.
        #  .o. => .o.
        #  ..x    ..x
        board[0][0] = ttt.player_symbol
        board[1][1] = ttt.computer_symbol
        board[2][2] = ttt.player_symbol

        ttt.make_move

        # Do not mark the corners which would result in a player fork.
        board[0][2].should be_nil
        board[2][0].should be_nil

        # One of the four edges should be marked.
        results = [board[0][1] == ttt.computer_symbol, board[1][0] == ttt.computer_symbol,
          board[1][2] == ttt.computer_symbol, board[2][1] == ttt.computer_symbol]
        results.select { |r| r }.count.should == 1
      end
    end
  end

  describe 'remaining moves' do
    it 'should mark the center' do
      expect {
        ttt.make_move
      }.to change { board[1][1] }.to(ttt.computer_symbol)
    end

    it 'should mark the opposite corner' do
      # o..
      # xxo
      # o.x
      board[0][0] = ttt.computer_symbol
      board[1][0] = ttt.player_symbol
      board[1][1] = ttt.player_symbol
      board[1][2] = ttt.computer_symbol
      board[2][0] = ttt.computer_symbol
      board[2][2] = ttt.player_symbol

      expect {
        ttt.make_move
      }.to change { board[0][2] }.to(ttt.computer_symbol)
    end

    it 'should mark any corner' do
      board[1][1] = ttt.player_symbol

      ttt.make_move

      results = TicTacToe::CORNERS.reduce([]) do |results, pos|
        results << (board[pos.first][pos.last] == ttt.computer_symbol)
      end
      results.select { |r| r }.count.should == 1
    end
  end

  describe '#winner' do
    %w{computer player}.map(&:to_sym).each do |type|
      it "should return :#{type} if the #{type} won" do
        board[0][0] = ttt.send("#{type}_symbol")
        board[1][1] = ttt.send("#{type}_symbol")
        board[2][2] = ttt.send("#{type}_symbol")

        ttt.winner.should == type
      end
    end

    it 'should return nil if there is no winner' do
      ttt.winner.should == nil
    end
  end

  describe '#two_of_a_kind' do
    it 'should return the index of nil and the symbol' do
      %w{computer_symbol player_symbol}.map(&:to_sym).each do |type|
        symbol = ttt.send(type)
        ttt.send(:two_of_a_kind, [symbol, symbol, nil], symbol).should == 2
      end
    end

    it 'should return nil if there are not two of the same symbol' do
      %w{computer_symbol player_symbol}.map(&:to_sym).each do |type|
        symbol = ttt.send(type)
        ttt.send(:two_of_a_kind, [ttt.computer_symbol, ttt.player_symbol, nil], symbol).should == nil
      end
    end

    it 'should return nil if there is no nil element' do
      %w{computer_symbol player_symbol}.map(&:to_sym).each do |type|
        symbol = ttt.send(type)
        ttt.send(:two_of_a_kind, [ttt.computer_symbol, ttt.computer_symbol, ttt.player_symbol], symbol).should == nil
      end
    end
  end

end
