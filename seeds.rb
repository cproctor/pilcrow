def gran(int)
	if int % 100 == 0
		100
	elsif int % 10 == 0
		10
	else
		1
	end
end
CSV.foreach("dewey-raw.txt") do |row|
	d=DeweyClass.new(	:number => row[0].to_i, 
										:description => row[1], 
										:granularity => gran(row[0].to_i))
	d.save
end