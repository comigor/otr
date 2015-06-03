Router.route '/',
	where: 'server'
	action: ->
		@response.writeHead 302,
			'Location': 'http://linkedin.com/in/Igor1201'
		@response.end()

Meteor.publish 'mySocket', ->
	Socket.find {to: @userId}

Meteor.publish 'user', (_id) ->
	Meteor.users.find {_id: {$in: [_id]}}, {fields: {emails: 1}}

Meteor.publish 'allUsers', ->
	if @userId
		Meteor.users.find {_id: {$ne: @userId}}, {fields: {emails: 1}}
	else
		[]
