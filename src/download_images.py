import pygame
import os

def download_images(asset):
    img_path = os.path.join("assets/img", asset)
    
    images = {}
    for file in os.listdir(img_path):
        img_name = file.split('.')[0]
        try:
            images[img_name] = pygame.image.load(os.path.join(img_path, file))
        except:
            print(f"Error loading image {img_name}")
    return images