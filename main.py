import chess
import pygame
import requests
import os

from download_images import download_images


# Constants
TILE_SIZE = 64
BOARD_SIZE = 8
SCREEN_SIZE = TILE_SIZE * BOARD_SIZE

# Pygame Initialization
pygame.init()
screen = pygame.display.set_mode((SCREEN_SIZE, SCREEN_SIZE))
pygame.display.set_caption("Chessboard Visualization")

# Load piece images
piece_images = {}

piece_images = download_images("pieces")

# Load tile images
tile_images = download_images("tiles")

# Chess board setup
board = chess.Board()

# Function to draw the board
def draw_board():
    for row in range(BOARD_SIZE):
        for col in range(BOARD_SIZE):
            tile_image = tile_images['light'] if (row + col) % 2 == 0 else tile_images['dark']
            screen.blit(tile_image, (col * TILE_SIZE, row * TILE_SIZE))

# Function to draw pieces
def draw_pieces():
    for square in chess.SQUARES:
        piece = board.piece_at(square)
        if piece:
            piece_str = piece.symbol()
            color = 'w' if piece_str.isupper() else 'b'
            piece_img = piece_images[color + piece_str.upper()]
            x = (square % 8) * TILE_SIZE + (TILE_SIZE - piece_img.get_width()) // 2
            y = (7 - (square // 8)) * TILE_SIZE + (TILE_SIZE - piece_img.get_height()) // 2  # Flip vertically

            screen.blit(piece_img, (x, y))

# Function to handle piece movement
def handle_piece_movement(event):
    global selected_square, dragging_piece

    if event.type == pygame.MOUSEBUTTONDOWN:
        x, y = event.pos
        col = x // TILE_SIZE
        row = 7 - (y // TILE_SIZE)
        selected_square = chess.square(col, row)
        dragging_piece = board.piece_at(selected_square)

    elif event.type == pygame.MOUSEBUTTONUP:
        if dragging_piece:
            x, y = event.pos
            col = x // TILE_SIZE
            row = 7 - (y // TILE_SIZE)
            target_square = chess.square(col, row)
            move = chess.Move(selected_square, target_square)
            if move in board.legal_moves:
                board.push(move)
            selected_square = None
            dragging_piece = None

# Game Loop
running = True
while running:
    screen.fill((0, 0, 0))
    draw_board()
    draw_pieces()
    pygame.display.flip()

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        handle_piece_movement(event)
pygame.quit()


stockfish_api = "https://stockfish.online/api/s/v2.php"
params={
    "fen" : "rn1q1rk1/pp2b1pp/2p2n2/3p1pB1/3P4/1QP2N2/PP1N1PPP/R4RK1 b - - 1 11",
    "depth" : "1"
    }

move = requests.get(stockfish_api, params=params)
print(move.json())
