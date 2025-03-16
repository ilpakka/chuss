import pygame
import chess
from src.download_images import download_images

class Game:
    def __init__(self, screen, TILE_SIZE, BOARD_SIZE):
        self.TILE_SIZE = TILE_SIZE
        self.BOARD_SIZE = BOARD_SIZE
        self.screen = screen

        # Load piece images
        self.piece_images = {}

        self.piece_images = download_images("pieces")

        # Load tile images
        self.tile_images = download_images("tiles")

        # Chess board setup
        self.board = chess.Board()

    # Function to draw the board
    def draw_board(self):
        for row in range(self.BOARD_SIZE):
            for col in range(self.BOARD_SIZE):
                tile_image = self.tile_images['light'] if (row + col) % 2 == 0 else self.tile_images['dark']
                self.screen.blit(tile_image, (col * self.TILE_SIZE, row * self.TILE_SIZE))

    # Function to draw pieces
    def draw_pieces(self):
        for square in chess.SQUARES:
            piece = self.board.piece_at(square)
            if piece:
                piece_str = piece.symbol()
                color = 'w' if piece_str.isupper() else 'b' # upper white, lower black
                piece_img = self.piece_images[color + piece_str.upper()] # wP, bP, wR, bR, etc.
                x = (square % 8) * self.TILE_SIZE + (self.TILE_SIZE - piece_img.get_width()) // 2 # Center horizontally
                y = (7 - (square // 8)) * self.TILE_SIZE + (self.TILE_SIZE - piece_img.get_height()) // 2  # Flip (id=0 bottom) and center vertically
                self.screen.blit(piece_img, (x, y))

    # Function to handle piece movement
    def handle_piece_movement(self, event):
        global selected_square, dragging_piece

        if event.type == pygame.MOUSEBUTTONDOWN:
            x, y = event.pos
            col = x // self.TILE_SIZE
            row = 7 - (y // self.TILE_SIZE)
            selected_square = chess.square(col, row)
            dragging_piece = self.board.piece_at(selected_square)

        elif event.type == pygame.MOUSEBUTTONUP:
            if dragging_piece:
                x, y = event.pos
                col = x // self.TILE_SIZE
                row = 7 - (y // self.TILE_SIZE)
                target_square = chess.square(col, row)
                move = chess.Move(selected_square, target_square)
                if move in self.board.legal_moves:
                    self.board.push(move)
                selected_square = None
                dragging_piece = None

if __name__ == "__main__":
    Game()

    