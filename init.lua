return function()
	if path:sub(1,1)~="/" then
		return ""
	end
	if path:sub(-1,-1)~="/" then
		path = path .. "/"
	end

	local appropriatepath = (fs.list and path) or var.webroot..path

	if not (fs.exists or os.exists)(appropriatepath) then
		context.Next()
		return
	end

	local tbl=tag"table"[{class="index"}](
		tag"thead"(
			tag"tr"(
				tag"th"(
					"Name"
				),
				tag"th"(
					"Type"
				),
				tag"th"(
					"Size"
				),
				tag"th"(
					"Last modified"
				)
			)
		)
	)
	local function sizefmt(s)
		if s>=1024*1024*1000 then
			s=s/0x40000000
			local d=10^(math.floor(math.log(s)/math.log(10))-2)
			return tag"div"[{class="sizeg"}]((math.floor(s/d)*d).."G")
		elseif s>=1024*1000 then
			s=s/0x100000
			local d=10^(math.floor(math.log(s)/math.log(10))-2)
			return tag"div"[{class="sizem"}]((math.floor(s/d)*d).."M")
		elseif s>=1000 then
			s=s/0x400
			local d=10^(math.floor(math.log(s)/math.log(10))-2)
			return tag"div"[{class="sizek"}]((math.floor(s/d)*d).."K")
		end
		return s
	end
	local escapist = require("escapist")
	local files, err = (fs.list or io.list)(appropriatepath)
	if err then
		context.Next()
		return
	end
	table.insert(files, 1, "..")
	local options = {}
	if not err then
		for _, l in pairs(files) do
			local c,a=l:match"^(%S+) (.*)$"
			c,a=(c or l):lower(),a or ""
			if not options[c] then
				options[c]={a}
			else
				table.insert(options[c],a)
			end
		end
	end
	for _, file in pairs(files) do
		local found
		if options.hidden then
			for _,v in ipairs(options.hidden) do
				if file:match("^"..v.."$") then
					found=true
					break
				end
			end
		end
		if not found then
			local t, s, d
			if (fs.isDir or io.isDir) and (fs.size or io.size) and (fs.modtime or io.modtime) then
				t = (fs.isDir or io.isDir)(path..file) and "directory" or "regular file"
				s = (fs.size or io.size)(path..file)
				d = (fs.modtime or io.modtime)(path..file)
			else
				local f=io.popen("stat -Lc %F\\\t%s\\\t%Y "..escapist.escape.shell(var.root..path..file))
				local fmt=f:read"*a"
				t,s,d=fmt:match"^([^\t]*)\t([^\t]*)\t(.*)\n$"
				if not t then error(fmt) end
				f:close()
				s,d=tonumber(s),tonumber(d) 
			end
			tbl(
				tag"tr"(
					tag"td"(
						tag"a"[{href=path..escapist.escape.url(file)}](
							file
						)
					),
					tag"td"(
						t
					),
					tag"td"(
						sizefmt(tonumber(s)or-1)
					),
					tag"td"[{class="lastmod"}](
						os.date("%c",tonumber(d)or 0)
					)
				)
			)
		end
	end
	local body=tag"body"
	if options.header then
		body:force_content(table.concat(options.header,"\n"))
	end
	body(tbl)
	if options.footer then
		body:force_content(table.concat(options.footer,"\n"))
	end
	if options.fake then
		for _,v in ipairs(options.fake) do
			local fname,url,tp,sz,lm=v:match"^([^,]*),([^,]*),([^,]*),([^,]*),(.*)$"
			if fname then
				tbl(
					tag"tr"(
						tag"td"(
							tag"a"[{href=url}](
								fname
							)
						),
						tag"td"(
							tp
						),
						tag"td"(
							sizefmt(tonumber(sz)or-1)
						),
						tag"td"[{class="lastmod"}](
							os.date("%c",tonumber(lm)or 0)
						)
					)
				)
			end
		end
	end
	local title="Index of "..path
	if options.title then
		title=table.concat(options.title,"\n")
	end
	content(doctype()(
		tag"html"(
			tag"head"(
	--			tag"link"[{rel="stylesheet",href="/core/design.css"}],
	--			tag"link"[{rel="stylesheet",href="/core/index.css"}],
				tag"style"[{media="screen",type="text/css"}]([[
	a{
		color:#9fee00;
		text-decoration:none;
	}
	a:hover{
		text-decoration:underline;
	}
	body{
		background:#000000;
		color:#eeeeee;
	}
	input[type="text"]{
		border: 1px solid #9fee00;
		background: #000;
		color: #9fee00;
	}
	input[type="submit"]{
		border: 1px solid #9fee00;
		background: #9fee00;
		color: #000;
	}
	.index *{
		font-family:monospace;
	}
	.index th{
		color:#ffd300;
		text-align:left;
	}
	table.index{
		border:0px;
		padding:0px;
		border-collapse:collapse;
	}
	.index th,.index td{
		padding:1px 4px;
	}
	.index tbody tr:hover{
		background:#9fee00;
		color:#000000;
	}
	.sizek{color:#ccffcc;}
	.sizem{color:#ffffcc;}
	.sizeg{color:#ffcccc;}
	.lastmod{color:#aaaaaa;}
	tr:hover .sizek{color:#000000;}
	tr:hover .sizem{color:#000000;}
	tr:hover .sizeg{color:#000000;}
	tr:hover .lastmod{color:#000000;}
	.index tr:hover a{color:#000000;}
				]]),
				tag"title"(
					title
				)
			),
			body
		)
	))
end
