
User.all.destroy_all
u0 = User.create! organization_name: 'Biosmart Admin', email: 'admin@earthguardians.life', password: '123456', role: 'admin'
u1 = User.create! organization_name: 'Tokyo Inc', email: 'prw20042004@yahoo.co.uk', password: '123456'

DataSource.all.destroy_all
DataSource.create! name: 'iNaturalist'
DataSource.create! name: 'Questagame'
DataSource.create! name: 'Ebird'
DataSource.create! name: 'observation.org'

Contest.all.destroy_all
#Contest.create! title: 'Tokyo Sakura Challenge', description: 'Get your flower pictures in!', starts_at: '2022-04-01T00:00', ends_at: '2022-04-15T00:00', status: Contest.statuses[:online]
#Contest.create! title: 'Tokyo Spooky Spring Insects Challenge', description: 'As it gets warmer, they will appear on your balcony...', starts_at: '2022-04-15T00:00', ends_at: '2022-05-15T00:00', status: Contest.statuses[:online]
c0 = Contest.create! title: 'City Nature Challenge 2022', description: 'Started in 2016 as a competition between San Francisco and Los Angeles, the City Nature Challenge (CNC) has grown into an international event, motivating people around the world to find and document wildlife in their cities. Run by the Community Science teams at the California Academy of Sciences and the Natural History Museum of Los Angeles County, the CNC is an annual four-day global bioblitz at the end of April, where cities are in a collaboration-meets-friendly-competition to see not only what can be accomplished when we all work toward a common goal, but also which city can gather the most observations of nature, find the most species, and engage the most people in the event.', starts_at: '2022-04-29T00:00.00', ends_at: '2022-05-3T00:00.00', status: Contest.statuses[:online]


# browser console: { name: PROJECT_DATA.title, description: PROJECT_DATA.description, header_image_url: PROJECT_DATA.header_image_url, logo_image_url: PROJECT_DATA.icon, inaturalist_place_id: PROJECT_DATA.place_id }

Region.all.destroy_all
Region.create! user_id: u0.id, name: 'Surrey BC', description: 'Join the City of Surrey (BC, Canada) for our third…dible natural values to be found in our backyard.', header_image_url: 'https://static.inaturalist.org/projects/121407-cover.jpg?1637103100', logo_image_url: 'https://static.inaturalist.org/projects/121407-icon-span2.JPG?1637103100', inaturalist_place_id: 144780
Region.create! user_id: u0.id, name: 'Chicago Metro', description: 'Take the City Nature Challenge! Search for wild pl…ari@chicagoparkdistrict.com for more information.', header_image_url: 'https://static.inaturalist.org/projects/107272-cover.png?1643594300', logo_image_url: 'https://static.inaturalist.org/projects/107272-icon-span2.png?1643583576', inaturalist_place_id: 1859
Region.create! user_id: u0.id, name: 'Montréal, Québec, Canada', description: "(English follows.)  C'est facile!  Montrez au mond…", header_image_url: 'https://static.inaturalist.org/projects/121508-cover.png?1645389759', logo_image_url: 'https://static.inaturalist.org/projects/121508-icon-span2.png?1637200749', inaturalist_place_id: 147597
Region.create! user_id: u0.id, name: 'Lane County City', description: 'Join your friends and neighbors in documenting loc…ecies, and engage the most people in the event.', header_image_url: 'https://static.inaturalist.org/projects/123548-cover.png?1639689710', logo_image_url: 'https://static.inaturalist.org/projects/123548-icon-span2.png?1639689709', inaturalist_place_id: 981
Region.create! user_id: u0.id, name: 'KielRegion', description: 'Erkunde die Artenvielfalt in der KielRegion! Zum …am mit dem Langen Tag der Stadtnatur Kiel statt.', header_image_url: 'https://static.inaturalist.org/projects/122892-cover.jpg?1639133711', logo_image_url: 'https://static.inaturalist.org/projects/122892-icon-span2.png?1639133711', inaturalist_place_id: 98634
Region.create! user_id: u0.id, name: 'Maribor'
Region.create! user_id: u0.id, name: 'Mendoza UNICIPIO', description: 'Participá en la Competencia Natural de la Ciudad 2…org/projects/city-nature-challenge-2022', header_image_url: nil, logo_image_url: 'https://static.inaturalist.org/projects/126384-icon-span2.png?1646605628', inaturalist_place_id: 165173
Region.create! user_id: u0.id, name: 'Wichita Falls, Texas -Rolling Plains Chapter TMN Region', description: 'Join the Rolling Plains Chapter of Texas Master Na…unity\r\nLearn more as your finds get identified!\r\n', header_image_url: 'https://static.inaturalist.org/projects/122120-cover.jpg?1639711464', logo_image_url: 'https://static.inaturalist.org/projects/122120-icon-span2.png?1644976232', inaturalist_place_id: 1548
Region.create! user_id: u0.id, name: 'Thailand', description: 'Help Thailand show the world how amazing our regio…ี้ สำเร็จได้ด้วยการกดปุ่ม เพียงปุ่มเดียวเท่านั้น!', header_image_url: 'https://static.inaturalist.org/projects/126286-cover.jpg?1643599067', logo_image_url: 'https://static.inaturalist.org/projects/126286-icon-span2.jpg?1643599067', inaturalist_place_id: 9845
Region.create! user_id: u0.id, name: 'Veracruz Metropolitano', description: 'Te invitamos a participar en el Reto Naturalista U… protegerte a ti, a tus vecinos y a tu comunidad.', header_image_url: 'https://static.inaturalist.org/projects/124808-cover.jpg?1641877664', logo_image_url: 'https://static.inaturalist.org/projects/124808-icon-span2.jpg?1641852608', inaturalist_place_id: 180429
Region.create! user_id: u0.id, name: 'Baton Rouge', description: 'The City Nature Challenge is a four-day friendly n… to May 2, 2022. http://www.brnaturechallenge.org', header_image_url: 'https://static.inaturalist.org/projects/123540-cover.jpg?1643756459', logo_image_url: 'https://static.inaturalist.org/projects/123540-icon-span2.jpg?1639769458', inaturalist_place_id: 124
Region.create! user_id: u0.id, name: 'Fort Wayne Area', description: 'Join us in our third year as participants in the C… have specific data to help track these changes. ', header_image_url: 'https://static.inaturalist.org/projects/126512-cover.png?1643823450', logo_image_url: 'https://static.inaturalist.org/projects/126512-icon-span2.jpg?1643823125', inaturalist_place_id: 2094
Region.create! user_id: u0.id, name: 'Khanty-Mansiysk, Russia', description: 'Khanty-Mansiysk, Russia: City Nature Challenge 202…ожения или сайта iNaturalist. Присоединяйтесь!', header_image_url: 'https://static.inaturalist.org/projects/124698-cover.png?1641739574', logo_image_url: 'https://static.inaturalist.org/projects/124698-icon-span2.jpg?1641739573', inaturalist_place_id: 149950
Region.create! user_id: u0.id, name: 'Valle de Aburrá', description: 'El Reto Naturalista  conocido a nivel mundial como…poya el evento a través de los links de difusión.', header_image_url: 'https://static.inaturalist.org/projects/122621-cover.JPG?1646339114', logo_image_url: 'https://www.inaturalist.org/attachment_defaults/general/span2.png', inaturalist_place_id: 144768
Region.create! user_id: u0.id, name: 'Saskatoon, SK', description: 'Help put the Saskatoon area on the world nature', header_image_url: 'https://static.inaturalist.org/projects/121234-cover.jpg?1647206866', logo_image_url: 'https://static.inaturalist.org/projects/121234-icon-span2.jpg?1637013462', inaturalist_place_id: 177596
Region.create! user_id: u0.id, name: 'Birmingham & Black Country', description: 'Help us to document the wildlife of Birmingham and…tal and help move us up the global leaderboard!', header_image_url: 'https://static.inaturalist.org/projects/124583-cover.png?1641564638', logo_image_url: 'https://static.inaturalist.org/projects/124583-icon-span2.png?1641568338', inaturalist_place_id: 144101
Region.create! user_id: u0.id, name: 'Madison County, KY', description: 'This is the 2022 City Nature Challenge Project for Madison County, KY', header_image_url: nil, logo_image_url: 'https://static.inaturalist.org/projects/122281-icon-span2.jfif?1638292397', inaturalist_place_id: 1982
Region.create! user_id: u0.id, name: 'Boston Area', description: 'Massachusetts has a great diversity of life, from …https://www.inaturalist.org/observations/77493850', header_image_url: 'https://static.inaturalist.org/projects/121680-cover.jpg?1643989996', logo_image_url: 'https://static.inaturalist.org/projects/121680-icon-span2.png?1637366844', inaturalist_place_id: 146061
Region.create! user_id: u0.id, name: 'Lexington-Fayette County, KY, USA', description: 'Floracliff Nature Sanctuary, Lexington Parks & Rec…ease download the iNaturalist app in advance.', header_image_url: 'https://static.inaturalist.org/projects/122436-cover.jpeg?1644021816', logo_image_url: 'https://static.inaturalist.org/projects/122436-icon-span2.png?1645738095', inaturalist_place_id: 1958
Region.create! user_id: u0.id, name: 'Coffs Harbour'
Region.create! user_id: u0.id, name: 'Port Harcourt/Iwofe', description: 'Another exciting year for Center for Environment, …biodiversity mapping. it is going to be fun......', header_image_url: 'https://static.inaturalist.org/projects/128900-cover.jpg?1646851456', logo_image_url: 'https://static.inaturalist.org/projects/128900-icon-span2.jpg?1646851455', inaturalist_place_id: 49426
Region.create! user_id: u0.id, name: 'Greater Philadelphia Area', description: 'Philadelphia is competing in the City Nature Chall…hallenge-2021-greater-philadelphia-area?tab=about', header_image_url: 'https://static.inaturalist.org/projects/122609-cover.png?1638813525', logo_image_url: 'https://static.inaturalist.org/projects/122609-icon-span2.png?1638813753', inaturalist_place_id: 298
Region.create! user_id: u0.id, name: 'Louisville Metro', description: "From April 29 - May 2, 2022, let's take a break fr…ojects/kentucky-city-nature-challenge-2022-cities", header_image_url: 'https://static.inaturalist.org/projects/124604-cover.jpg?1644348806', logo_image_url: 'https://static.inaturalist.org/projects/124604-icon-span2.jpg?1643059042', inaturalist_place_id: 757
Region.create! user_id: u0.id, name: 'Görlitz', description: 'Erkunde die Artenvielfalt in der Stadt Görlitz! Z…enckenberg Museum für Naturkunde Görlitz geplant.', header_image_url: 'https://static.inaturalist.org/projects/125186-cover.jpg?1642173444', logo_image_url: 'https://static.inaturalist.org/projects/125186-icon-span2.png?1642173443', inaturalist_place_id: 98625
Region.create! user_id: u0.id, name: 'San Miguel de Tucumán y Alrededores', description: 'Participá en la Competencia Natural de la Ciudad 2…uralist.org/projects/city-nature-challenge-2022\r\n', header_image_url: 'https://static.inaturalist.org/projects/128995-cover.jpg?1646925984', logo_image_url: 'https://static.inaturalist.org/projects/128995-icon-span2.png?1648326567', inaturalist_place_id: 14083
Region.create! user_id: u0.id, name: 'Cleveland-Akron-Canton-Toledo', description: 'Join the Cleveland, Akron, Canton, and Toledo regi…the Natural History Museum of Los Angeles County.', header_image_url: 'https://static.inaturalist.org/projects/122353-cover.jpg?1642788934', logo_image_url: 'https://static.inaturalist.org/projects/122353-icon-span2.png?1642788934', inaturalist_place_id: 179337
Region.create! user_id: u0.id, name: 'São Paulo', description: 'Cada dia mais as pessoas dos grandes centros urban…es - vamos divulgar essa beleza para o Mundo!', header_image_url: 'https://static.inaturalist.org/projects/124585-cover.png?1644319149', logo_image_url: 'https://static.inaturalist.org/projects/124585-icon-span2.png?1644317650', inaturalist_place_id: 25311
Region.create! user_id: u0.id, name: 'Poconé', description: 'Cada dia mais as pessoas se distanciam da Natureza…es - vamos divulgar essa beleza para o Mundo!', header_image_url: nil, logo_image_url: 'https://static.inaturalist.org/projects/126906-icon-span2.png?1644318700', inaturalist_place_id: 21529
Region.create! user_id: u0.id, name: 'Culiacán, Sinaloa', description: 'Este  2022 sera el primer Reto Naturalista Urbano …nto de la flora y fauna silvestre del municipio. ', header_image_url: 'https://static.inaturalist.org/projects/123860-cover.JPG?1640190041', logo_image_url: 'https://static.inaturalist.org/projects/123860-icon-span2.png?1640190040', inaturalist_place_id: 49407
Region.create! user_id: u0.id, name: 'Calgary Metropolitan Region', description: "Now entering it's fourth year, Calgary will once a…nformation, news, and events leading up to event!", header_image_url: 'https://static.inaturalist.org/projects/119508-cover.jpg?1644516136', logo_image_url: 'https://static.inaturalist.org/projects/119508-icon-span2.jpg?1644513585', inaturalist_place_id: 132936
Region.create! user_id: u0.id, name: 'Área Conurbada Morelia', description: 'Reto Naturalista Urbano 2022, en esta ocasión.', header_image_url: 'https://static.inaturalist.org/projects/124353-cover.jpg?1648767328', logo_image_url: 'https://static.inaturalist.org/projects/124353-icon-span2.jpg?1648762223', inaturalist_place_id: 37190

Region.all.each do |r|
  Participation.create! contest_id: c0.id, region_id: r.id, status: Participation.statuses[:accepted], user_id: u0.id	
end















