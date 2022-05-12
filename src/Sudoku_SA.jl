# Sudoku by Simulated Annealing
# シミュレーティッドアニーリング（焼きなまし法）による数独
struct Sudoku
    # 枠全体：縦x横x数字
    unit::Array{Int8, 3}

    # 固定位置
    fixed::Vector{Tuple{Int64,Int64}}

    function Sudoku(fixed::Matrix{Int64})
        # 初期化
        u = zeros(Int8, 9, 9, 9)
        f = []
        for x = 1:9
            for y = 1:9
                if fixed[x, y] != 0
                    push!(f, (x, y))
                    # 固定値が指定されていればそれを設定
                    z = fixed[x, y]
                    u[x, y, z] = 1
                else
                    # 指定がなければ乱数を設定
                    z = rand(1:9)
                    u[x, y, z] = 1
                end
            end
        end
        
        new(u, f)
    end
end

function energy(board::Sudoku)
    #
    # エネルギー計算
    # 最適解の場合に、エネルギー=0となる
    #
    e = 0
    # row
    e += sum([(sum([board.unit[x, y, z] for y = 1:9]) - 1)^2 for x = 1:9 for z = 1:9])
    
    # col
    e += sum([(sum([board.unit[x, y, z] for x = 1:9]) - 1)^2 for y = 1:9 for z = 1:9])

    # block
    e += sum([(sum([board.unit[x+i, y+j, z] for i = 0:2 for j = 0:2]) - 1)^2 for x = 1:3:7 for y = 1:3:7 for z = 1:9])

    return e
end

function change(board::Sudoku, x, y, r)
    # 指定されたrの分だけ要素をrotateする → 数字変化
    # 常に1の値は一つのみで、ワンホット状態が維持される
    for z1 = 1:9
        if board.unit[x, y, z1] == 1
            z2 = (z1 - 1 + r) % 9 + 1
            board.unit[x, y, z1], board.unit[x, y, z2] = 0, 1
            break
        end
    end
end

function display(board::Sudoku)
    println()

    for x = 1:9
        s = []
        for y = 1:9
            for z = 1:9
                if board.unit[x, y, z] == 1
                    push!(s, z)
                    break
                end
            end
        end
        println("[" * join(s, ", ") * "]")
    end
end

function run(board::Sudoku, temp_start, temp_end, alpha, temp_iter)
    now_energy = energy(board)

    temperature = temp_start
    while temperature > temp_end && now_energy > 0
        for i = 1:temp_iter
            # 一か所変化させる
            cx = rand(1:9)
            cy = rand(1:9)

            # 固定値のマスが指定されたらやり直し
            while (cx, cy) in board.fixed
                cx = rand(1:9)
                cy = rand(1:9)
            end
            r = rand(1:8)
            change(board, cx, cy, r)

            # エネルギー値の計算
            new_energy = energy(board)
            # 変化前とのエネルギー値の差分
            de = new_energy - now_energy

            # eval
            if exp(- de / temperature) > rand()    # 条件 (de < 0) 含む 
                # 変化を許す
                now_energy = new_energy
                #display(board)
                #println("energy = ", now_energy, "temp = ", temperature)

                # 解に到達したら終了
                if now_energy == 0
                    return (true, now_energy, temperature)
                end
            else
                # 変化を許さないので元に戻す
                change(board, cx, cy, 9-r)
            end
        end
        #display(board)
        #println("energy = ", now_energy, " temp = ", temperature)

        # 温度を減衰
        temperature = temperature * alpha
    end

    return (false, now_energy, temperature)
end

if abspath(PROGRAM_FILE) == @__FILE__
    fixed = [
        5 3 0 0 7 0 0 0 0
        6 0 0 1 9 5 0 0 0
        0 9 8 0 0 0 0 6 0
        8 0 0 0 6 0 0 0 3
        4 0 0 8 0 3 0 0 1
        7 0 0 0 2 0 0 0 6
        0 6 0 0 0 0 2 8 0
        0 0 0 4 1 9 0 0 5
        0 0 0 0 8 0 0 7 9
        ]

    # 開始温度
    temp_start = 1000
    # 減衰率
    alpha = 0.99
    # 終了温度
    temp_end = 0.02
    # 温度当たりの繰り返し数
    temp_iter = 1000

    board = Sudoku(fixed)
    (result, ene, temp), runtime = @timed run(board, temp_start, temp_end, alpha, temp_iter)

    display(board)
    println("energy = ", ene, ", temp = ", temp)
    if result
        println("OK")
    end
    println(runtime, " sec")
end
