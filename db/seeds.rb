
User.all.destroy_all
u0 = User.create! organization_name: 'Biosmart Admin', email: 'admin@earthguardians.life', password: '123456', role: 'admin'
u1 = User.create! organization_name: 'Tokyo Inc', email: 'prw20042004@yahoo.co.uk', password: '123456'

DataSource.all.destroy_all
DataSource.create! name: 'iNaturalist'
DataSource.create! name: 'Questagame'
DataSource.create! name: 'Ebird'
DataSource.create! name: 'observation.org'

Contest.all.destroy_all
Contest.create! title: 'Tokyo Sakura Challenge', description: 'Get your flower pictures in!', starts_at: '2022-04-01T00:00', ends_at: '2022-04-15T00:00', status: Contest.statuses[:online]
Contest.create! title: 'Tokyo Spooky Spring Insects Challenge', description: 'As it gets warmer, they will appear on your balcony...', starts_at: '2022-04-15T00:00', ends_at: '2022-05-15T00:00', status: Contest.statuses[:online]
