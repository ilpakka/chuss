import chess
import requests

board = chess.Board()
stockfish_api = "https://stockfish.online/api/s/v2.php"
params={
    "fen" : "rn1q1rk1/pp2b1pp/2p2n2/3p1pB1/3P4/1QP2N2/PP1N1PPP/R4RK1 b - - 1 11",
    "depth" : "1"
    }

move = requests.get(stockfish_api, params=params)
print(move.json())