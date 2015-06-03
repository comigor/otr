@Chat = {}

Template.chat.onRendered ->
	Chat.buddy = @data.buddy
	Chat.key = new DSA()
	Chat.user = new OTR
		fragment_size: 140
		send_interval: 200
		priv: Chat.key

	# unencrypted message received
	Chat.user.on 'ui', (msg, enc) ->
		Session.set 'end2end', Session.get('end2end') + '<p>' + (if enc then '<img src="http://www.hl7.org/FHIR/2015May/lock.png"> ' else ' ') + Chat.buddy.emails[0]?.address + ': ' + msg + '</p>'
	
	# encrypted message, send to buddy
	Chat.user.on 'io', (msg) ->
		Socket.insert
			from: Meteor.userId()
			to: Chat.buddy._id
			msg: msg
	
	Chat.user.on 'status', (state) ->
		if state == OTR.CONST.STATUS_AKE_SUCCESS and Chat.user.msgstate == OTR.CONST.MSGSTATE_ENCRYPTED
			Session.set 'otr', true
			Session.set 'buddyKey', Chat.user.their_priv_pk.fingerprint()
		else if state == OTR.CONST.STATUS_END_OTR and Chat.user.msgstate == OTR.CONST.MSGSTATE_FINISHED
			Chat.user.endOtr()
			Session.set 'otr', false
			Session.set 'buddyKey', null

	Session.set 'end2end', ''
	Session.set 'otr', false
	Session.set 'myKey', Chat.key.fingerprint()
	Session.set 'buddyKey', null

	Socket.find({}).observe
		added: (obj) ->
			if obj.to == Meteor.userId()
				Chat.user.receiveMsg obj.msg
				Socket.remove obj._id

Template.chat.helpers
	final: -> Session.get 'end2end'
	myKey: -> Session.get 'myKey'
	buddyKey: -> Session.get 'buddyKey'
	otr: -> Session.get 'otr'

Template.list.helpers
	email: -> @emails[0]?.address

Template.chat.events
	'click #test': ->
		$('#test').attr 'disabled', true
		Chat.user.sendQueryMsg()
	'click #end': ->
		Chat.user.endOtr ->
			Session.set 'otr', false
			Session.set 'buddyKey', null
	'submit #form': (e) ->
		e.preventDefault()
		msg = e.target.msg.value
		Session.set 'end2end', Session.get('end2end') + '<p>me: ' + msg + '</p>'
		Chat.user.sendMsg msg
		$('[name="msg"]').val ''
