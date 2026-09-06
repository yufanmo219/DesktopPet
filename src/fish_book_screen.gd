class_name FishBookScreen
extends StoreScreen

## Dedicated fish encyclopedia. It reuses the approved open-book artwork and
## fish catalog layout without exposing the cat-adoption catalog.


func configure_book(stats: Dictionary) -> void:
	configure(stats, ["maple"], "fish")
