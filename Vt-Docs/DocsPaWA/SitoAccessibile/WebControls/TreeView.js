var persisteduls=new Object()
var ddtreemenu=new Object()

ddtreemenu.closefolder="./images/tree-folder.gif" //set image path to "closed" folder image
ddtreemenu.openfolder="./images/tree-folder-open.gif" //set image path to "open" folder image

//////////No need to edit beyond here///////////////////////////

ddtreemenu.createTree=function(treeid, enablepersist, persistdays){
	
	var ultags=document.getElementById(treeid).getElementsByTagName("ul")
	
	if (typeof persisteduls[treeid]=="undefined")
		persisteduls[treeid]=(enablepersist==true && ddtreemenu.getCookie(treeid)!="")? ddtreemenu.getCookie(treeid).split(",") : ""
	for (var i=0; i<ultags.length; i++)
		ddtreemenu.buildSubTree(treeid, ultags[i], i)
	if (enablepersist==true){ //if enable persist feature
		var durationdays=(typeof persistdays=="undefined")? 1 : parseInt(persistdays)
		
	ddtreemenu.dotask(window, function(){ddtreemenu.rememberstate(treeid, durationdays)}, "unload") //save opened UL indexes on body unload
	}
}

ddtreemenu.buildSubTree=function(treeid, ulelement, index){
	
	//ulelement.parentNode.className="submenu"
	ulelement.parentNode.className="closednode"
	
	if (typeof persisteduls[treeid]=="object"){ //if cookie exists (persisteduls[treeid] is an array versus "" string)
		if (ddtreemenu.searcharray(persisteduls[treeid], index)){
			ulelement.setAttribute("title", "Nodo aperto")
			ulelement.style.display="block"
			//ulelement.parentNode.style.backgroundImage="url("+ddtreemenu.openfolder+")"
			//ulelement.parentNode.setAttribute("class", "openednode")
			ulelement.parentNode.className = "openednode"
		}
		else
			ulelement.setAttribute("title", "Nodo chiuso")
		} //end cookie persist code
	else if (ulelement.getAttribute("title")==null || ulelement.getAttribute("title")==false) //if no cookie and UL has NO title attribute explicted added by user
		ulelement.setAttribute("title", "Nodo chiuso")
	else if (ulelement.getAttribute("title")=="Nodo aperto") //else if no cookie and this UL has an explicit title value of "Nodo aperto"
		ddtreemenu.expandSubTree(treeid, ulelement) //expand this UL plus all parent ULs (so the most inner UL is revealed!)
		ulelement.parentNode.onclick=function(e){
		var submenu=this.getElementsByTagName("ul")[0]
	
	if (submenu.getAttribute("title")=="Nodo chiuso"){
		submenu.style.display="block"
		submenu.setAttribute("title", "Nodo aperto")
		//ulelement.parentNode.style.backgroundImage="url("+ddtreemenu.openfolder+")"
		//ulelement.parentNode.setAttribute("class", "openednode")
		ulelement.parentNode.className = "openednode"
	}
	else if (submenu.getAttribute("title")=="Nodo aperto"){
		submenu.style.display="none"
		submenu.setAttribute("title", "Nodo chiuso")
		//ulelement.parentNode.style.backgroundImage="url("+ddtreemenu.closefolder+")"
		//ulelement.parentNode.setAttribute("class", "closednode")
		ulelement.parentNode.className = "closednode"
	}
	ddtreemenu.preventpropagate(e)
	}
	ulelement.onclick=function(e){
		ddtreemenu.preventpropagate(e)
	}
}

ddtreemenu.expandSubTree=function(treeid, ulelement){ //expand a UL element and any of its parent ULs

	var rootnode=document.getElementById(treeid)
	var currentnode=ulelement
	currentnode.style.display="block"
	//currentnode.parentNode.style.backgroundImage="url("+ddtreemenu.openfolder+")"
	//currentnode.parentNode.setAttribute("class", "openednode")
	currentnode.parentNode.className = "openednode"
	
	while (currentnode!=rootnode){
		if (currentnode.tagName=="UL"){ //if parent node is a UL, expand it too
			currentnode.style.display="block"
			currentnode.setAttribute("title", "Nodo aperto") //indicate it's open
			//currentnode.parentNode.style.backgroundImage="url("+ddtreemenu.openfolder+")"
			//currentnode.parentNode.setAttribute("class", "openednode")
			currentnode.parentNode.className = "openednode"
		}
		currentnode=currentnode.parentNode
	}
}

ddtreemenu.flatten=function(treeid, action){ //expand or contract all UL elements

	var ultags=document.getElementById(treeid).getElementsByTagName("ul")
	
	for (var i=0; i<ultags.length; i++){
		ultags[i].style.display=(action=="expand")? "block" : "none"
		var relvalue=(action=="expand")? "Nodo aperto" : "Nodo chiuso"
		ultags[i].setAttribute("title", relvalue)
		//ultags[i].parentNode.style.backgroundImage=(action=="expand")? "url("+ddtreemenu.openfolder+")" : "url("+ddtreemenu.closefolder+")"
		var parentclass=(action=="expand")? "openednode" : "closednode"
		//alert (parentclass)
		ultags[i].parentNode.className = parentclass
	}
}

ddtreemenu.rememberstate=function(treeid, durationdays){ //store index of opened ULs relative to other ULs in Tree into cookie
	var ultags=document.getElementById(treeid).getElementsByTagName("ul")
	var openuls=new Array()
	for (var i=0; i<ultags.length; i++){
		if (ultags[i].getAttribute("title")=="Nodo aperto")
			openuls[openuls.length]=i //save the index of the opened UL (relative to the entire list of ULs) as an array element
		}
	if (openuls.length==0) //if there are no opened ULs to save/persist
		openuls[0]="none open" //set array value to string to simply indicate all ULs should persist with state being closed
	ddtreemenu.setCookie(treeid, openuls.join(","), durationdays) //populate cookie with value treeid=1,2,3 etc (where 1,2... are the indexes of the opened ULs)
}

////A few utility functions below//////////////////////

ddtreemenu.getCookie=function(Name){ //get cookie value
	var re=new RegExp(Name+"=[^;]+", "i"); //construct RE to search for target name/value pair
	if (document.cookie.match(re)) //if cookie found
		return document.cookie.match(re)[0].split("=")[1] //return its value
	return ""
}

ddtreemenu.setCookie=function(name, value, days){ //set cookei value
	var expireDate = new Date()
	//set "expstring" to either future or past date, to set or delete cookie, respectively
	var expstring=expireDate.setDate(expireDate.getDate()+parseInt(days))
	document.cookie = name+"="+value+"; expires="+expireDate.toGMTString()+"; path=/";
}

ddtreemenu.searcharray=function(thearray, value){ //searches an array for the entered value. If found, delete value from array
	var isfound=false
	for (var i=0; i<thearray.length; i++){
		if (thearray[i]==value){
			isfound=true
			thearray.shift() //delete this element from array for efficiency sake
			break
		}
	}
	return isfound
}

ddtreemenu.preventpropagate=function(e){ //prevent action from bubbling upwards
	if (typeof e!="undefined")
		e.stopPropagation()
	else
		event.cancelBubble=true
	}

ddtreemenu.dotask=function(target, functionref, tasktype){ //assign a function to execute to an event handler (ie: onunload)
	var tasktype=(window.addEventListener)? tasktype : "on"+tasktype
	if (target.addEventListener)
		target.addEventListener(tasktype, functionref, false)
	else if (target.attachEvent)
		target.attachEvent(tasktype, functionref)
}