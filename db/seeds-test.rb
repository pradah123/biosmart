
User.all.destroy_all
u0 = User.create! organization_name: 'Biosmart Admin', email: 'admin@earthguardians.life', password: '123456', role: 'admin'
u1 = User.create! organization_name: 'Tokyo Inc', email: 'prw20042004@yahoo.co.uk', password: '123456'

DataSource.all.destroy_all
DataSource.create! name: 'Source A'
DataSource.create! name: 'Source B'
DataSource.create! name: 'Source C'

Contest.all.destroy_all
c0 = Contest.create! title: 'Contest I', description: '', starts_at: '2022-05-01T00:00.00', ends_at: '2022-05-02T00:00.00', status: Contest.statuses[:online]
c1 = Contest.create! title: 'Contest II', description: '', starts_at: '2022-05-02T00:00.00', ends_at: '2022-05-03T00:00.00', status: Contest.statuses[:online]

Region.all.destroy_all
Region.create! user_id: u0.id, name: 'Region A', description: '', header_image_url: '', logo_image_url: ''
Region.create! user_id: u0.id, name: 'Region B', description: '', header_image_url: '', logo_image_url: ''

Region.all.each do |r|
  Participation.create! contest_id: c0.id, region_id: r.id, status: Participation.statuses[:accepted], user_id: u0.id	
end

Observation.create! lat: , lng:













