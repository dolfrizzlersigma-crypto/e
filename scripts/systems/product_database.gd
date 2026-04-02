extends Node
class_name ProductDatabase

## ====================================================================================
## PRODUCT DATABASE SYSTEM
## ====================================================================================
## Comprehensive product catalog for convenience store
## Manages inventory, pricing, categories, and product data
## ====================================================================================

signal product_added(product_id: String)
signal product_removed(product_id: String)
signal inventory_updated(product_id: String, new_quantity: int)
signal price_changed(product_id: String, new_price: float)
signal category_added(category_name: String)

# ====================================================================================
# PRODUCT CATEGORIES
# ====================================================================================

enum ProductCategory {
	BEVERAGES_COLD,
	BEVERAGES_HOT,
	SNACKS_CHIPS,
	SNACKS_CANDY,
	SNACKS_COOKIES,
	FOOD_SANDWICHES,
	FOOD_HOT_DOGS,
	FOOD_BAKERY,
	TOBACCO,
	AUTOMOTIVE,
	HEALTH_BEAUTY,
	HOUSEHOLD,
	ELECTRONICS,
	READING_MATERIAL,
	LOTTERY,
	ALCOHOL,
	MISC
}

# ====================================================================================
# DATA STRUCTURES
# ====================================================================================

var products: Dictionary = {}  # product_id -> product_data
var inventory: Dictionary = {}  # product_id -> quantity
var categories: Dictionary = {}  # category -> Array[product_ids]
var barcodes: Dictionary = {}  # barcode -> product_id

# ====================================================================================
# INITIALIZATION
# ====================================================================================

func _ready() -> void:
	_initialize_product_catalog()
	_initialize_inventory()
	print("ProductDatabase: Initialized with %d products" % products.size())

func _initialize_product_catalog() -> void:
	# BEVERAGES - COLD DRINKS
	_add_product("BEV_SODA_COLA_001", {
		"name": "Classic Cola",
		"category": ProductCategory.BEVERAGES_COLD,
		"price": 1.99,
		"barcode": "0001234567891",
		"description": "16oz Can - Refreshing cola beverage",
		"brand": "CoolCola",
		"size": "16oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("BEV_SODA_COLA_002", {
		"name": "Diet Cola",
		"category": ProductCategory.BEVERAGES_COLD,
		"price": 1.99,
		"barcode": "0001234567892",
		"description": "16oz Can - Zero sugar cola",
		"brand": "CoolCola",
		"size": "16oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("BEV_ENERGY_001", {
		"name": "NightShift Energy",
		"category": ProductCategory.BEVERAGES_COLD,
		"price": 3.49,
		"barcode": "0001234567893",
		"description": "16oz Can - Extra caffeine",
		"brand": "PowerUp",
		"size": "16oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("BEV_WATER_001", {
		"name": "Spring Water",
		"category": ProductCategory.BEVERAGES_COLD,
		"price": 1.79,
		"barcode": "0001234567894",
		"description": "20oz Bottle - Pure spring water",
		"brand": "ClearWater",
		"size": "20oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("BEV_SPORTS_001", {
		"name": "ElectroBoost",
		"category": ProductCategory.BEVERAGES_COLD,
		"price": 2.29,
		"barcode": "0001234567895",
		"description": "32oz Bottle - Electrolyte drink",
		"brand": "AthletePro",
		"size": "32oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("BEV_JUICE_001", {
		"name": "Orange Juice",
		"category": ProductCategory.BEVERAGES_COLD,
		"price": 2.99,
		"barcode": "0001234567896",
		"description": "16oz Bottle - 100% juice",
		"brand": "SunnyGrove",
		"size": "16oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("BEV_MILK_001", {
		"name": "Whole Milk",
		"category": ProductCategory.BEVERAGES_COLD,
		"price": 3.49,
		"barcode": "0001234567897",
		"description": "Half Gallon - Fresh dairy",
		"brand": "FarmFresh",
		"size": "0.5gal",
		"taxable": false,
		"age_restricted": false
	})

	_add_product("BEV_ICED_TEA_001", {
		"name": "Iced Tea Lemon",
		"category": ProductCategory.BEVERAGES_COLD,
		"price": 1.99,
		"barcode": "0001234567898",
		"description": "20oz Bottle - Sweetened tea",
		"brand": "TeaTime",
		"size": "20oz",
		"taxable": true,
		"age_restricted": false
	})

	# BEVERAGES - HOT DRINKS
	_add_product("BEV_COFFEE_REG_001", {
		"name": "Regular Coffee",
		"category": ProductCategory.BEVERAGES_HOT,
		"price": 1.49,
		"barcode": "0002234567891",
		"description": "12oz Cup - Fresh brewed",
		"brand": "House Blend",
		"size": "12oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("BEV_COFFEE_LRG_001", {
		"name": "Large Coffee",
		"category": ProductCategory.BEVERAGES_HOT,
		"price": 1.99,
		"barcode": "0002234567892",
		"description": "20oz Cup - Fresh brewed",
		"brand": "House Blend",
		"size": "20oz",
		"taxable": true,
		"age_restricted": false
	})

	# SNACKS - CHIPS
	_add_product("SNK_CHIPS_001", {
		"name": "Classic Potato Chips",
		"category": ProductCategory.SNACKS_CHIPS,
		"price": 2.49,
		"barcode": "0003234567891",
		"description": "Regular size bag",
		"brand": "CrunchTime",
		"size": "2.5oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("SNK_CHIPS_002", {
		"name": "Sour Cream Chips",
		"category": ProductCategory.SNACKS_CHIPS,
		"price": 2.49,
		"barcode": "0003234567892",
		"description": "Regular size bag",
		"brand": "CrunchTime",
		"size": "2.5oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("SNK_CHIPS_003", {
		"name": "Barbecue Chips",
		"category": ProductCategory.SNACKS_CHIPS,
		"price": 2.49,
		"barcode": "0003234567893",
		"description": "Regular size bag",
		"brand": "CrunchTime",
		"size": "2.5oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("SNK_CHIPS_004", {
		"name": "Nacho Cheese Chips",
		"category": ProductCategory.SNACKS_CHIPS,
		"price": 2.79,
		"barcode": "0003234567894",
		"description": "Tortilla chips with cheese",
		"brand": "FiestaSnacks",
		"size": "3oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("SNK_PRETZELS_001", {
		"name": "Salted Pretzels",
		"category": ProductCategory.SNACKS_CHIPS,
		"price": 1.99,
		"barcode": "0003234567895",
		"description": "Twisted pretzels",
		"brand": "TwistSnacks",
		"size": "2oz",
		"taxable": true,
		"age_restricted": false
	})

	# SNACKS - CANDY
	_add_product("SNK_CANDY_001", {
		"name": "Chocolate Bar",
		"category": ProductCategory.SNACKS_CANDY,
		"price": 1.29,
		"barcode": "0004234567891",
		"description": "Milk chocolate bar",
		"brand": "ChocoDelight",
		"size": "1.5oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("SNK_CANDY_002", {
		"name": "Peanut Butter Cups",
		"category": ProductCategory.SNACKS_CANDY,
		"price": 1.49,
		"barcode": "0004234567892",
		"description": "Chocolate peanut butter",
		"brand": "NuttySweets",
		"size": "1.5oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("SNK_CANDY_003", {
		"name": "Gummy Bears",
		"category": ProductCategory.SNACKS_CANDY,
		"price": 1.79,
		"barcode": "0004234567893",
		"description": "Fruit flavored gummies",
		"brand": "BearCub",
		"size": "2oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("SNK_CANDY_004", {
		"name": "Hard Candy Mix",
		"category": ProductCategory.SNACKS_CANDY,
		"price": 0.99,
		"barcode": "0004234567894",
		"description": "Assorted hard candies",
		"brand": "SweetMix",
		"size": "1oz",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("SNK_GUM_001", {
		"name": "Spearmint Gum",
		"category": ProductCategory.SNACKS_CANDY,
		"price": 0.99,
		"barcode": "0004234567895",
		"description": "Pack of 15",
		"brand": "FreshBreath",
		"size": "15ct",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("SNK_MINTS_001", {
		"name": "Breath Mints",
		"category": ProductCategory.SNACKS_CANDY,
		"price": 1.49,
		"barcode": "0004234567896",
		"description": "Strong mints",
		"brand": "IcyFresh",
		"size": "50ct",
		"taxable": true,
		"age_restricted": false
	})

	# FOOD - SANDWICHES & PREPARED
	_add_product("FOOD_SAND_001", {
		"name": "Ham & Cheese Sandwich",
		"category": ProductCategory.FOOD_SANDWICHES,
		"price": 5.99,
		"barcode": "0005234567891",
		"description": "Fresh made sandwich",
		"brand": "DailyFresh",
		"size": "1 sandwich",
		"taxable": false,
		"age_restricted": false
	})

	_add_product("FOOD_SAND_002", {
		"name": "Turkey Club",
		"category": ProductCategory.FOOD_SANDWICHES,
		"price": 6.49,
		"barcode": "0005234567892",
		"description": "Triple decker sandwich",
		"brand": "DailyFresh",
		"size": "1 sandwich",
		"taxable": false,
		"age_restricted": false
	})

	_add_product("FOOD_HOTDOG_001", {
		"name": "Classic Hot Dog",
		"category": ProductCategory.FOOD_HOT_DOGS,
		"price": 2.99,
		"barcode": "0005234567893",
		"description": "Roller grill hot dog",
		"brand": "House",
		"size": "1 hot dog",
		"taxable": false,
		"age_restricted": false
	})

	_add_product("FOOD_BURRITO_001", {
		"name": "Bean & Cheese Burrito",
		"category": ProductCategory.FOOD_SANDWICHES,
		"price": 3.49,
		"barcode": "0005234567894",
		"description": "Microwave burrito",
		"brand": "QuickMeal",
		"size": "6oz",
		"taxable": false,
		"age_restricted": false
	})

	# BAKERY
	_add_product("FOOD_DONUT_001", {
		"name": "Glazed Donut",
		"category": ProductCategory.FOOD_BAKERY,
		"price": 1.49,
		"barcode": "0006234567891",
		"description": "Fresh glazed donut",
		"brand": "Morning Treats",
		"size": "1 donut",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("FOOD_MUFFIN_001", {
		"name": "Blueberry Muffin",
		"category": ProductCategory.FOOD_BAKERY,
		"price": 2.29,
		"barcode": "0006234567892",
		"description": "Fresh baked muffin",
		"brand": "Morning Treats",
		"size": "1 muffin",
		"taxable": true,
		"age_restricted": false
	})

	# TOBACCO (Age Restricted)
	_add_product("TOB_CIG_001", {
		"name": "Premium Cigarettes",
		"category": ProductCategory.TOBACCO,
		"price": 8.99,
		"barcode": "0007234567891",
		"description": "Pack of 20",
		"brand": "LongRoad",
		"size": "20ct",
		"taxable": true,
		"age_restricted": true,
		"min_age": 21
	})

	_add_product("TOB_CIG_002", {
		"name": "Light Cigarettes",
		"category": ProductCategory.TOBACCO,
		"price": 8.49,
		"barcode": "0007234567892",
		"description": "Pack of 20",
		"brand": "LongRoad",
		"size": "20ct",
		"taxable": true,
		"age_restricted": true,
		"min_age": 21
	})

	# AUTOMOTIVE
	_add_product("AUTO_OIL_001", {
		"name": "Motor Oil 10W-30",
		"category": ProductCategory.AUTOMOTIVE,
		"price": 6.99,
		"barcode": "0008234567891",
		"description": "1 quart motor oil",
		"brand": "RoadRunner",
		"size": "1qt",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("AUTO_WASHER_001", {
		"name": "Windshield Washer Fluid",
		"category": ProductCategory.AUTOMOTIVE,
		"price": 3.99,
		"barcode": "0008234567892",
		"description": "1 gallon fluid",
		"brand": "ClearView",
		"size": "1gal",
		"taxable": true,
		"age_restricted": false
	})

	# HEALTH & BEAUTY
	_add_product("HB_ASPIRIN_001", {
		"name": "Pain Relief",
		"category": ProductCategory.HEALTH_BEAUTY,
		"price": 4.99,
		"barcode": "0009234567891",
		"description": "20 tablets",
		"brand": "QuickRelief",
		"size": "20ct",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("HB_BANDAID_001", {
		"name": "Adhesive Bandages",
		"category": ProductCategory.HEALTH_BEAUTY,
		"price": 3.49,
		"barcode": "0009234567892",
		"description": "Assorted sizes",
		"brand": "FirstAid",
		"size": "20ct",
		"taxable": true,
		"age_restricted": false
	})

	# HOUSEHOLD
	_add_product("HH_TISSUES_001", {
		"name": "Facial Tissues",
		"category": ProductCategory.HOUSEHOLD,
		"price": 2.49,
		"barcode": "0010234567891",
		"description": "Travel pack",
		"brand": "SoftTouch",
		"size": "10ct",
		"taxable": true,
		"age_restricted": false
	})

	# READING MATERIAL
	_add_product("READ_MAG_001", {
		"name": "Auto Magazine",
		"category": ProductCategory.READING_MATERIAL,
		"price": 5.99,
		"barcode": "0011234567891",
		"description": "Current issue",
		"brand": "RoadLife",
		"size": "Monthly",
		"taxable": true,
		"age_restricted": false
	})

	_add_product("READ_NEWS_001", {
		"name": "Daily Newspaper",
		"category": ProductCategory.READING_MATERIAL,
		"price": 1.50,
		"barcode": "0011234567892",
		"description": "Today's edition",
		"brand": "LocalNews",
		"size": "Daily",
		"taxable": false,
		"age_restricted": false
	})

	# ALCOHOL (Age Restricted)
	_add_product("ALC_BEER_001", {
		"name": "Domestic Beer 6-Pack",
		"category": ProductCategory.ALCOHOL,
		"price": 7.99,
		"barcode": "0012234567891",
		"description": "6 pack 12oz cans",
		"brand": "BudLight",
		"size": "6x12oz",
		"taxable": true,
		"age_restricted": true,
		"min_age": 21
	})

	_add_product("ALC_BEER_002", {
		"name": "Premium Beer Single",
		"category": ProductCategory.ALCOHOL,
		"price": 2.49,
		"barcode": "0012234567892",
		"description": "Single 16oz can",
		"brand": "CraftBrew",
		"size": "16oz",
		"taxable": true,
		"age_restricted": true,
		"min_age": 21
	})

	print("Product catalog initialized with %d products" % products.size())

func _initialize_inventory() -> void:
	# Set initial inventory levels for all products
	for product_id in products.keys():
		var initial_qty = randi_range(10, 50)  # Random starting inventory
		inventory[product_id] = initial_qty

# ====================================================================================
# PRODUCT MANAGEMENT
# ====================================================================================

func _add_product(product_id: String, product_data: Dictionary) -> void:
	products[product_id] = product_data

	# Add to barcode lookup
	if product_data.has("barcode"):
		barcodes[product_data.barcode] = product_id

	# Add to category
	var cat = product_data.get("category", ProductCategory.MISC)
	if not categories.has(cat):
		categories[cat] = []
	categories[cat].append(product_id)

	product_added.emit(product_id)

func get_product(product_id: String) -> Dictionary:
	return products.get(product_id, {})

func get_product_by_barcode(barcode: String) -> Dictionary:
	var product_id = barcodes.get(barcode, "")
	return get_product(product_id)

func get_products_by_category(category: ProductCategory) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var product_ids = categories.get(category, [])
	for product_id in product_ids:
		result.append(products[product_id])
	return result

# ====================================================================================
# INVENTORY MANAGEMENT
# ====================================================================================

func get_inventory_quantity(product_id: String) -> int:
	return inventory.get(product_id, 0)

func set_inventory_quantity(product_id: String, quantity: int) -> void:
	inventory[product_id] = max(0, quantity)
	inventory_updated.emit(product_id, quantity)

func add_inventory(product_id: String, quantity: int) -> void:
	var current = get_inventory_quantity(product_id)
	set_inventory_quantity(product_id, current + quantity)

func remove_inventory(product_id: String, quantity: int) -> bool:
	var current = get_inventory_quantity(product_id)
	if current >= quantity:
		set_inventory_quantity(product_id, current - quantity)
		return true
	return false

func is_in_stock(product_id: String) -> bool:
	return get_inventory_quantity(product_id) > 0

# ====================================================================================
# PRICING
# ====================================================================================

func get_price(product_id: String) -> float:
	var product = get_product(product_id)
	return product.get("price", 0.0)

func set_price(product_id: String, new_price: float) -> void:
	if products.has(product_id):
		products[product_id].price = new_price
		price_changed.emit(product_id, new_price)

# ====================================================================================
# SEARCH & FILTER
# ====================================================================================

func search_products(search_term: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var search_lower = search_term.to_lower()

	for product_data in products.values():
		var name_lower = product_data.get("name", "").to_lower()
		if name_lower.contains(search_lower):
			results.append(product_data)

	return results

func get_all_products() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for product_data in products.values():
		all.append(product_data)
	return all

func get_low_stock_products(threshold: int = 5) -> Array[Dictionary]:
	var low_stock: Array[Dictionary] = []
	for product_id in products.keys():
		if get_inventory_quantity(product_id) <= threshold:
			var product = products[product_id].duplicate()
			product["inventory"] = get_inventory_quantity(product_id)
			low_stock.append(product)
	return low_stock
