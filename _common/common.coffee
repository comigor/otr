@Socket = new Meteor.Collection 'socket'
Socket.allow
	insert: -> true
	remove: -> true

Router.route '/chat/:_id',
	name: '/chat'
	template: 'chat'
	waitOn: ->
		Meteor.subscribe 'mySocket'
		Meteor.subscribe 'user', @params._id
	onBeforeAction: ->
		if @params._id == Meteor.userId()
			@redirect '/list'
		else
			bigint = IRLibLoader.load '/otr/dep/bigint.js'
			if bigint.ready()
				crypto = IRLibLoader.load '/otr/dep/crypto.js'
				if crypto.ready()
					eventemitter = IRLibLoader.load '/otr/dep/eventemitter.js'
					if eventemitter.ready()
						otr = IRLibLoader.load '/otr/otr.min.js'
						if otr.ready()
							@next()
	data: ->
		buddy: Meteor.users.findOne @params._id

Router.route '/list',
	template: 'list'
	waitOn: ->
		Meteor.subscribe 'allUsers'
	data: ->
		users: Meteor.users.find {_id: {$ne: Meteor.userId()}}
