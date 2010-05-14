/* This file provides the fade-in effect via Javascript. If you don't like it, just delete it! */
/* Stolen from Smooth Operator 2.0b5 */


// Here we set up a fader to slowly fade the chat in on load.
var fader = new Fadomatic(document.getElementById("Chat"));

// This is the fader
function Fadomatic (element)
{
    element.style.opacity = 0;
    this._element = element;
    this._opacity = 0;
    var objref = this;
    this._intervalId = setInterval(function() { objref._tickFade(); },15);
}

// And here's what gets called by the fader and actually changes the opacity.
Fadomatic.prototype._tickFade = function ()
{
    this._opacity += 0.05;
    if (this._opacity >= 1) clearInterval(this._intervalId);
    this._element.style.opacity = this._opacity;
}

// Redefine the function which adds new messages so we can slip in the fading code
function appendMessage(html) {
    var shouldScroll = nearBottom();
    var insert = document.getElementById("insert");
    if(insert) insert.parentNode.removeChild(insert);
    var chat = document.getElementById("Chat");
    var range = document.createRange();
    range.selectNode(chat);
    var documentFragment = range.createContextualFragment(html);
    var myFrag = chat.appendChild(documentFragment);
    alignChat(shouldScroll);
    // Here's the new stuff. First we get a reference to the last child (the last message block in most cases).
    // Check the html to understand the structure of each message we add.
    var nodeToFade = chat.lastChild;
    // Next check to see if that's the "insert" div - as it is with status messages.
    // If so we need to skip back a node to get the actual message.
    if (nodeToFade.id == "insert") nodeToFade = nodeToFade.previousSibling;
    // Fade it!
    var fader2 = new Fadomatic(nodeToFade);
}

// Redefine the function which appends consecutive messages from the same person.
// Unfortunately necessary as even though we don't fade additional chat messages, consecutive status messages are added through this!
function appendNextMessage(html)
{
    shouldScroll = nearBottom();
    insert = document.getElementById("insert");
    range = document.createRange();
    range.selectNode(insert.parentNode);
    newNode = range.createContextualFragment(html);
    insert.parentNode.replaceChild(newNode,insert);
    alignChat(shouldScroll);
    // Here's the new stuff. Like before, we get the last child.
    var nodeToFade = document.getElementById("Chat").lastChild;
    // Check if it's an "insert" - the status message characteristic.
    if (nodeToFade.id == "insert")
    {
    // If so switch to the previous node, and fade!
    nodeToFade = nodeToFade.previousSibling;
    var fader3 = new Fadomatic(nodeToFade);
    }
}
