namespace :geojson do
  task :get, [:relation_id] do |t,args|
  	coordinates = []

  	r = HTTParty.get "https://api.openstreetmap.org/api/0.6/relation/#{args[:way_id]}.json", headers: { 'User-Agent' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36', 'Accept' => 'application/json' }
  	puts r.inspect
  	members = r['elements']['members']
  	puts "Got relationship, #{members.length} members"
  	puts r.inspect

  	members.each do |m|
  	  if m['type']=='way'  	
  	  	rr = HTTParty.get "https://api.openstreetmap.org/api/0.6/way/#{m['ref']}.json"
  	  	nodes = rr['elements']['nodes']
  		puts ">> Got way, #{nodes.length} nodes"
  		puts ">> #{r.inspect}"

  	  	nodes.each do |n|
  	  	  rrr = HTTParty.get "https://api.openstreetmap.org/api/0.6/node/#{n}.json"	
  	  	  c = { lat: rrr['elements'][0]['lat'], lng: rrr['elements'][0]['lon'] }
  	  	  coordinates.push c
  	  	end

  	  elsif m['type']=='node'
  	  	rr = HTTParty.get "https://api.openstreetmap.org/api/0.6/node/#{n}.json"	
  	  	c = { lat: rr['elements'][0]['lat'], lng: rr['elements'][0]['lon'] }
  	  	coordinates.push c

  	  end	
  	end

  	puts coordinates.inspect
  end 		
end