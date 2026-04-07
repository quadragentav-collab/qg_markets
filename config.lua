Config = {}

Config.Markets = {
    ['silah'] = {
        label = 'Silah Mağazası',
        pedModel = "s_m_y_ammucity_01",
        TargetLabel = "Merhaba, silah satın almak istiyorum.",
        TargetResponse = "Elbette! Hangi silahı istiyorsun?",
        GreetingLabel = "Selamlar!",
        GreetingResponse = "Merhaba! Hoş geldin, nasılsın?",
        blip = {
            sprite = 110,
            color = 1,
            scale = 0.8,
            display = 4
        },
        requiresLicense = true,
        licenseItem = 'weaponlicense',
        locations = {
            {
                coords = vector3(-658.86, -939.19, 21.83),
                heading = 102.31
            },
            {
                coords = vector3(-326.33, 6081.83, 31.45),
                heading = 139.58
            },
            {
                coords = vector3(247.32, -51.88, 69.94),
                heading = 331.93
            },
            {
                coords = vector3(2564.39, 298.34, 108.74),
                heading = 270.5
            },
            {
                coords = vector3(-1112.28, 2697.81, 18.62),
                heading = 130.42
            },
            {
                coords = vector3(840.64, -1029.32, 28.19),
                heading = 281.9
            },
        },
        items = {
            {
                name = 'weapon_pistol',
                label = 'Pistol',
                price = 15000,
                category = 'silah'
            },
            {
                name = 'weapon_pistol_mk2',
                label = 'Pistol Mk II',
                price = 18000,
                category = 'silah'
            },
        }
    },
    ['hirdavat'] = {
        label = 'YouTool',
        pedModel = "a_m_y_smartcaspat_01",
        TargetLabel = "Merhaba, birkaç alet arıyorum.",
        TargetResponse = "Tabii ki! İhtiyacın olan her şey burada.",
        GreetingLabel = "Selamlar!",
        GreetingResponse = "Selam dostum! Bugün nasılsın?",
        blip = {
            sprite = 52,
            color = 3,
            scale = 0.8,
            display = 4
        },

        locations = {
            {
                coords = vector3(2737.01, 3462.19, 55.7),
                heading = 337.46
            },
        },
        items = {
            {
                name = 'weapon_crowbar',
                label = 'Levye',
                price = 2000,
                category = 'hirdavat'
            },
            {
                name = 'weapon_wrench',
                label = 'İngiliz Anahtarı',
                price = 1200,
                category = 'hirdavat'
            },
            {
                name = 'weapon_flashlight',
                label = 'El Feneri',
                price = 800,
                category = 'hirdavat'
            },
            {
                name = 'hoe',
                label = 'Çapa',
                price = 300,
                category = 'hirdavat'
            },
            {
                name = 'sickle',
                label = 'Çiftçi Bıçağı',
                price = 300,
                category = 'hirdavat'
            },
            {
                name = 'watering_can',
                label = 'Sulama Kabı',
                price = 150,
                category = 'hirdavat'
            },
            {
                name = 'fertilizer',
                label = 'Gübre',
                price = 250,
                category = 'hirdavat'
            },
            {
                name = 'pesticide',
                label = 'Böcek İlacı',
                price = 300,
                category = 'hirdavat'
            }
        }
    },	
    ['teknoloji'] = {
        label = 'DigitalDen',
        pedModel = "a_m_m_socenlat_01",
        TargetLabel = "Merhaba, teknoloji ürünlerine bakacağım.",
        TargetResponse = "Harika! En son teknolojiler burada!",
        GreetingLabel = "Selamlar!",
        GreetingResponse = "Merhaba! Teknoloji dünyasına hoş geldin!",
        blip = {
            sprite = 52,
            color = 3,
            scale = 0.8,
            display = 4
        },

        locations = {
            {
                coords = vector3(-1529.87, -402.0, 35.64),
                heading = 231.08
            },
            {
                coords = vector3(1132.32, -474.35, 66.72),
                heading = 347.88
            },
        },
        items = {
            {
                name = 'iphone',
                label = 'Telefon',
                price = 500,
                category = 'teknoloji'
            },
            {
                name = 'radio',
                label = 'Telsiz',
                price = 370,
                category = 'teknoloji'
            },
            {
                name = 'vehicle_gps',
                label = 'Takip Cihazı',
                price = 2000,
                category = 'teknoloji'
            }
        }
    },
	
    ['havalimantech'] = {
        label = 'DigitalDen',
        pedModel = "a_m_m_socenlat_01",
        TargetLabel = "Merhaba, teknoloji ürünlerine bakacağım.",
        TargetResponse = "Hoş geldin! Seyahat için teknoloji mi?",
        GreetingLabel = "Selamlar!",
        GreetingResponse = "Havaalanına hoş geldin! Ne arıyorsun?",
        blip = {
            sprite = 52,
            color = 3,
            scale = 0.8,
            display = 4
        },

        locations = {
            {
                coords = vector3(-1142.68, -2785.77, 21.46),
                heading = 329.08
            },
        },
        items = {
            {
                name = 'iphone',
                label = 'Telefon',
                price = 1000,
                category = 'havalimantech'
            }
        }
    },
	
    ['burgershot'] = {
        label = 'BurgerShot',
        pedModel = "a_m_y_gencaspat_01",
        TargetLabel = "Merhaba, karnım aç. Bir şeyler almak istiyorum.",
        TargetResponse = "Elbette! En lezzetli burgerler burada!",
        GreetingLabel = "Selamlar!",
        GreetingResponse = "Selam! BurgerShot'a hoş geldin dostum!",
        blip = {
            sprite = 52,
            color = 3,
            scale = 0.8,
            display = 4
        },

        locations = {
            {
                coords = vector3(-1188.05, -894.67, 13.8),
                heading = 34.52
            },
            {
                coords = vector3(-1189.77, -895.82, 13.8),
                heading = 34.52
            },
        },
        items = {
            {
                name = 'burger',
                label = 'Burger',
                price = 20,
                category = 'burgershot'
            },
            {
                name = 'cola',
                label = 'Kola',
                price = 10,
                category = 'burgershot'
            }
        }
    },
    ['supermarket'] = {
        label = '24/7 Supermarket',
        pedModel = "mp_m_shopkeep_01",
        TargetLabel = "Merhaba, biraz bakınayım.",
        TargetResponse = "Tabii! Her şey taze ve uygun fiyatlı!",
        GreetingLabel = "Selamlar!",
        GreetingResponse = "Merhaba! 24/7'ye hoş geldin, yardıma ihtiyacın var mı?",
        blip = {
            sprite = 52,
            color = 2,
            scale = 0.8,
            display = 4
        },
        locations = {
            {
                coords = vector3(24.407, -1347.283, 29.497),
                heading = 270.311
            },
            {
                coords = vector3(1959.83, 3740.34, 32.40),
                heading = 301.65
            },
            {
                coords = vector3(1727.99, 6415.55, 35.04),
                heading = 246.65
            },
            {
                coords = vector3(-3039.45, 584.28, 8.0),
                heading = 13.13
            },
            {
                coords = vector3(-46.89, -1758.48, 29.42),
                heading = 52.46
            },
            {
                coords = vector3(1164.89, -323.26, 69.21),
                heading = 94.04
            },
            {
                coords = vector3(-705.83, -914.39, 19.22),
                heading = 94.04
            },
            {
                coords = vector3(-1819.34, 793.64, 138.08),
                heading = 139.54
            },
            {
                coords = vector3(2677.66, 3279.59, 55.24),
                heading = 333.32
            },
            {
                coords = vector3(1134, -982.2, 46.4),
                heading = 281.5
            },
            {
                coords = vector3(-2966.15, 390.97, 15.04),
                heading = 85.3
            },
            {
                coords = vector3(-1486.40, -377.64, 40.16),
                heading = 138.08
            },
            {
                coords = vector3(-1222.06, -908.46, 12.33),
                heading = 39.08
            },
            {
                coords = vector3(1165.98, 2711.01, 38.16),
                heading = 188.08
            },
            {
                coords = vector3(1391.96, 3606.18, 34.98),
                heading = 188.08
            },
            {
                coords = vector3(372.33, 326.49, 103.57),
                heading = 253.4
            },
            {
                coords = vector3(2557.25, 380.75, 108.62),
                heading = 355.4
            },
            {
                coords = vector3(1697.52, 4923.26, 42.06),
                heading = 332.4
            },
            {
                coords = vector3(-2071.17, -333.24, 13.32),
                heading = 351.56
            },
            {
                coords = vector3(160.32, 6641.87, 31.69),
                heading = 216.45
            },
            {
                coords = vector3(-163.03, 6323.06, 31.59),
                heading = 315.91
            },
            {
                coords = vector3(-2539.11, 2313.91, 33.22),
                heading = 92.69
            },
        },
        items = {
            {
                name = 'chips',
                label = 'Cips',
                price = 4,
                category = 'supermarket'
            },
            {
                name = 'water',
                label = 'Su',
                price = 3,
                category = 'supermarket'
            },
            {
                name = 'sprunk',
                label = 'Sprunk',
                price = 5,
                category = 'supermarket'
            },
            {
                name = 'cola',
                label = 'Kola',
                price = 5,
                category = 'supermarket'
            },
            {
                name = 'coffee',
                label = 'Kahve',
                price = 8,
                category = 'supermarket'
            },
            {
                name = 'beer',
                label = 'Bira',
                price = 8,
                category = 'supermarket'
            },
            {
                name = 'sandwich',
                label = 'Sandviç',
                price = 20,
                category = 'supermarket'
            },
            {
                name = 'bread',
                label = 'Ekmek',
                price = 3,
                category = 'supermarket'
            },
            {
                name = 'redwoodpack',
                label = 'Sigara Paketi',
                price = 20,
                category = 'supermarket'
            },
            {
                name = 'lighter',
                label = 'Çakmak',
                price = 5,
                category = 'supermarket'
            },
            {
                name = 'mustard',
                label = 'Hardal',
                price = 16,
                category = 'supermarket'
            },
            {
                name = 'wallet',
                label = 'Cüzdan',
                price = 24,
                category = 'supermarket'
            },
            {
                name = 'backpack',
                label = 'Sırt Çantası',
                price = 123,
                category = 'supermarket'
            }
        }
    }
}

-- VENDING MACHINES CONFIGURATION
Config.VendingMachines = {
    ['VendingMachineDrinks'] = {
        name = 'Sprunk Otomatı',
        inventory = {
            { name = 'sprunk', label = 'Sprunk', price = 10 },
            { name = 'cola', label = 'Kola', price = 10 },
        },
        model = {
            `prop_vend_soda_02`
        },
        targetLabel = "Sprunk Otomatını Kullan",
        type = "vending"
    },
    
    ['VendingMachineDrinks2'] = {
        name = 'Kola Otomatı',
        inventory = {
            { name = 'cola', label = 'Kola', price = 10 },
            { name = 'sprunk', label = 'Sprunk', price = 10 },
        },
        model = {
            `prop_vend_soda_01`
        },
        targetLabel = "Kola Otomatını Kullan",
        type = "vending"
    },
    
    ['VendingMachineDrinks3'] = {
        name = 'Atıştırmalık Otomatı',
        inventory = {
            { name = 'chips', label = 'Cips', price = 15 },
        },
        model = {
            `prop_vend_snak_01`
        },
        targetLabel = "Atıştırmalık Otomatını Kullan",
        type = "vending"
    },
    
    ['VendingMachineDrinks4'] = {
        name = 'Kahve Otomatı',
        inventory = {
            { name = 'coffee', label = 'Kahve', price = 10 },
        },
        model = {
            `prop_vend_coffe_01`
        },
        targetLabel = "Kahve Otomatını Kullan",
        type = "vending"
    },
    ['VendingMachineDrinks4'] = {
        name = 'Su Otomatı',
        inventory = {
            { name = 'water', label = 'Su', price = 5 },
        },
        model = {
            `prop_vend_water_01`
        },
        targetLabel = "Su Otomatını Kullan",
        type = "vending"
    }
}


Config.PaymentMethods = {
    ['cash'] = {
        label = 'Nakit',
        account = 'cash'
    },
    ['bank'] = {
        label = 'Banka Kartı',
        account = 'bank'
    }
}

-- Selam verme sistemi ayarları
Config.GreetingSystem = {
    enabled = true,
    displayTime = 5000,
    textHeight = 1.0,
    textScale = 0.35,
    textColor = { r = 255, g = 255, b = 255, a = 255 }
}

Config.Language = {
    ['market_title'] = 'YouTool',
    ['search_placeholder'] = 'Bir şeyler ara...',
    ['category'] = 'Kategori',
    ['add_to_cart'] = 'Sepete Ekle',
    ['cart_total'] = 'Toplam',
    ['pay'] = 'Öde',
    ['clear_cart'] = 'Sepeti Temizle',
    ['exit'] = 'Çıkış',
    ['payment_screen'] = 'Ödeme Ekranı',
    ['payment_options'] = 'Seçenekler',
    ['cash'] = 'Nakit',
    ['bank_card'] = 'Banka Kartı',
    ['cancel'] = 'İptal',
    ['insufficient_funds'] = 'Yetersiz bakiye!',
    ['purchase_successful'] = 'Satın alma başarılı!',
    ['purchase_failed'] = 'Satın alma başarısız!',
    ['cart_empty'] = 'Sepetiniz boş!',
    ['license_required'] = 'Bu eşya için silah lisansı gerekiyor!',
    ['no_weapon_license'] = 'Silah lisansınız bulunmuyor!',
    ['greeting_sent'] = 'Selam verdin!',
    
    -- Vending Machine specific language
    ['vending_title'] = 'Otomat',
    ['vending_select_item'] = 'Ürün Seçin',
    ['vending_insert_money'] = 'Para Atın',
    ['vending_buy'] = 'Satın Al',
    ['vending_cancel'] = 'İptal',
    ['vending_out_of_stock'] = 'Stokta yok!',
    ['vending_insufficient'] = 'Yetersiz para!',
    ['vending_enjoy'] = 'Afiyet olsun!'
}

-- TOPTANCI CONFIGURATION
Config.Wholesaler = {
    location = vector4(2710.03, 3451.21, 55.7, 68.6),
    pedModel = "s_m_m_migrant_01",
    blip = {
        sprite = 478,
        color = 0,
        scale = 0.4,
        display = 4,
        showOnlyForOwners = true
    },
    targetLabel = "Toptancı ile Konuş",
    expressDeliveryMultiplier = 1.5,
    expressDeliveryTimeReduction = 0.5,
    baseDeliveryTime = 120,
    products = {}
}

for _, item in ipairs(Config.Markets['supermarket'].items) do
    table.insert(Config.Wholesaler.products, {
        name = item.name,
        label = item.label,
        price = item.price * 0.6,
        maxStock = 1000,
        category = 'supermarket'
    })
end