function init_json_reader()
	J_WHITESPACE = {}
	J_WHITESPACE[" "]=true
	J_WHITESPACE["	"]=true
	J_WHITESPACE[chr(10)]=true
	J_WHITESPACE[chr(13)]=true

	J_START_TABLE = "{"
	J_STOP_TABLE="}"
	J_START_LIST="["
	J_STOP_LIST="]"
	J_QUOTE="\""
	J_COLON=":"
	J_COMMA=","
	J_OBJ_STARTS={
		n=read_json_null,
		t=read_json_true,
		f=read_json_false,
	}
	J_OBJ_STARTS[J_QUOTE]=read_json_key_string
	J_OBJ_STARTS[J_START_TABLE]=read_json_table
	J_OBJ_STARTS[J_START_LIST]=read_json_list
	J_OBJ_STARTS["-"]=read_json_number

	for i = 0,9 do
		J_OBJ_STARTS[tostr(i)] = read_json_number
	end
	json_init = true
end

function load_json_file(filepath)
	-- Load and read a json file and return a list or table
	if not json_init then init_json_reader() end
	local text = fetch(filepath)
	assert(text!=nil,"Failed to load json file: "..filepath)
	return read_json(text)
end

function read_json(string)
	if not json_init then init_json_reader() end
	-- Read a json string and return a list or table.
	if #string == 0 then
		return nil
	end

	local i=skip_json_whitespace(string,1)

	if string[i] == J_START_TABLE then
		return read_json_table(string,i)
	elseif string[i] == J_START_LIST then
		return read_json_list(string,i)
	else
		assert(false,"Unexpected initial character encountered in json file: "..string[i])
	end
end

function skip_json_whitespace(string,i)
	-- Skip to the first non-whitespace character from position i
	while J_WHITESPACE[string[i]] do
		i+=1
		assert(i<=#string,"Unexpectedly hit end of file while skipping whitespace\nin json file")
	end
	return i
end

function read_json_table(string,i)
	local eot = false
	local tab = {}
	local k, v = nil, nil

	if string[i]==J_START_TABLE then
		i+=1
	end

	while not eot do
		k, v, i = read_json_table_entry(string, i)
		tab[k] = v
		i = skip_json_whitespace(string,i)
		if string[i]==J_COMMA then
			i+=1
		elseif string[i]==J_STOP_TABLE then
			i+=1
			eot=true
		else
			assert(
				false,
				"Unexpected character encounted after reading json entry with\nkey '"..tostr(k).."': "..tostr(string[i]).." "
			)
		end
	end
	return tab, i
end

function read_json_table_entry(string, i)
	local k, v = nil, nil
	i = skip_json_whitespace(string,i)
	k, i = read_json_key_string(string,i)
	i = skip_json_whitespace(string,i)
	assert(
		string[i] == J_COLON,
		"Expected colon following json key '"..k.."', found: "..string[i]
	)
	i = skip_json_whitespace(string,i+1)
	assert(
		J_OBJ_STARTS[string[i]]!=nil,
		"Unexpected value encounted while reading json entry\n'"..k.."', found: "..string[i]
	)
	v,i=J_OBJ_STARTS[string[i]](string,i)
	return k, v, i
end

function read_json_key_string(string,i)
	assert(
		string[i]!=J_STOP_TABLE,
		"Table ended while expecting entry, make sure you don't have a misplaced comma."
	)
	assert(
		string[i]==J_QUOTE,
		"Expected json key/string to start with double quote,\ninstead found: "..sub(string,i,i+10).."..."
	)
	i+=1

	local s = i	

	while string[i]!=J_QUOTE do
		i+=1
		assert(
			i<=#string,
			"Encountered end of json while reading key/string:\n"..sub(string,i,i+10).."..."
		)
	end
	return sub(string,s,i-1), i+1
end

function read_json_list(string, i)
	local eol = false
	local lis = {}
	local value = nil

	if string[i]==J_START_LIST then
		i+=1
	end

	while not eol do
		i = skip_json_whitespace(string,i)
		assert(
			string[i]!=J_STOP_LIST,
			"List ended while expecting entry, make sure you don't have a misplaced comma."
		)
		assert(
			J_OBJ_STARTS[string[i]]!=nil,
			"Unexpected value encounted while reading json list,\nfound: "..sub(string,i,i+10).."..."
		)
		value,i=J_OBJ_STARTS[string[i]](string,i)	

		add(lis,value)

		i = skip_json_whitespace(string,i)
		if string[i]==J_COMMA then
			i+=1
		elseif string[i]==J_STOP_LIST then
			i+=1
			eol=true
		else
			assert(
				false,
				"Unexpected character encounted after reading json list entry: "..string[i]
			)
		end
	end
	return lis, i
end

function read_json_null(string,i)
	assert(sub(string,i,i+3)=="null","Was expecting to read null during json file read, instead\nfound: "..sub(string,i,i+10).."...")
	i+=4
	return nil, i
end

function read_json_true(string,i)
	assert(sub(string,i,i+3)=="true","Was expecting to read true during json file read, instead\nfound: "..sub(string,i,i+10).."...")
	i+=4
	return true, i
end

function read_json_false(string,i)
	assert(sub(string,i,i+4)=="false","Was expecting to read false during json file read, instead\nfound: "..sub(string,i,i+10).."...")
	i+=5
	return false, i
end

function read_json_number(string,i)
	local s = i

	while not (
		J_WHITESPACE[string[i]] or 
		string[i]==J_COMMA or 
		string[i]==J_STOP_TABLE or
		string[i]==J_STOP_LIST
	) do
		i+=1
		assert(i<=#string,"Unexpectedly hit the end of json string while reading a number.")
	end

	return tonum(sub(string,s,i-1)), i
end