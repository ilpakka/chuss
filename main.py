import pygame
import requests

from src import Game
from src.download_images import download_images

# Constants
TILE_SIZE = 55
BOARD_SIZE = 8
SCREEN_SIZE = TILE_SIZE * BOARD_SIZE

# Pygame Initialization
pygame.init()
screen = pygame.display.set_mode((SCREEN_SIZE, SCREEN_SIZE))
pygame.display.set_caption("Chessboard Visualization")

game = Game.Game(screen, TILE_SIZE, BOARD_SIZE)

# Load piece images
piece_images = {}
piece_images = download_images("pieces")

# Load tile images
tile_images = download_images("tiles")

# Game Loop
running = True
while running:
    screen.fill((0, 0, 0))
    game.draw_board()
    game.draw_pieces()
    pygame.display.flip()

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        game.handle_piece_movement(event)
pygame.quit()


stockfish_api = "https://stockfish.online/api/s/v2.php"
params={
    "fen" : "rn1q1rk1/pp2b1pp/2p2n2/3p1pB1/3P4/1QP2N2/PP1N1PPP/R4RK1 b - - 1 11",
    "depth" : "1"
    }

move = requests.get(stockfish_api, params=params)
print(move.json())
