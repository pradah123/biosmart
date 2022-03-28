
User.all.destroy_all
u0 = User.create! organization_name: 'Biosmart Admin', email: 'admin@earthguardians.life', password: '123456', role: 'admin'
u1 = User.create! organization_name: 'Tokyo Inc', email: 'prw20042004@yahoo.co.uk', password: '123456'

DataSource.all.destroy_all
DataSource.create! name: 'iNaturalist'
DataSource.create! name: 'Questagame'
DataSource.create! name: 'Ebird'
DataSource.create! name: 'observation.org'


