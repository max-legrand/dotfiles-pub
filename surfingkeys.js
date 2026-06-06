const Hints = api.Hints;
// console.log(api)

// Use the omnibar for tabs always
settings.tabsThreshold = 0;

api.addVimMapKey(
    {
        keys: "jj",
        type: "keyToKey",
        toKeys: "<Esc>",
        context: "insert",
    }
)

// console.log(api)
// console.log(settings)
api.mapkey("O","Open in current tab", function () {
    api.Front.openOmnibar({
        type: "URLs",
        extra: "getTopSites", 
        tabbed: false
    })
})

api.mapkey("F", "Open in new tab", function () {
    api.Hints.create("", api.Hints.dispatchMouseClick, { tabbed: true, active: true });
});

// Toggle extension
api.map("<Alt-g>", "<Alt-s>");
// Passthru
api.map("<Ctrl-Alt-i>", "<Alt-i>");

// Remove unwanted custom/default binding that shows the "Hi im here now" popup.
api.unmap("w");

// Tab navigation
api.map("q", "E"); // previous tab
api.map("e", "R"); // next tab

api.Hints.characters = "asdfgqwertvbn";
api.Hints.style('border: solid 1px #cdc1ff; color:#44475a; background: #cdc1ff; background-color: #cdc1ff; font-size: 10pt; font-family: "M PLUS 1 Code"');
api.Hints.style('border: solid 8px #cdc1ff;padding: 1px;background: #cdc1ff; font-family: "M PLUS 1 Code"', "text");
api.Visual.style('marks', 'background-color: #f1fa8c;');
api.Visual.style('cursor', 'background-color: #6272a4; color: #f8f8f2');
settings.theme = `
.sk_theme input {
    font-family: "M PLUS 1 Code";
}
.sk_theme .url {
    /*font-size: 8px;*/
}
#sk_omnibarSearchResult li div.url {
    font-weight: normal;
}
.sk_theme .omnibar_timestamp {
    /*font-size: 9px;*/
    font-weight: bold;
}
#sk_omnibarSearchArea input {
    /*font-size: 10px;*/
}
.sk_theme .omnibar_visitcount {
    /* font-size: 9px; */
    font-weight: bold;
}
body {
    font-family: "M PLUS 1 Code", monospace;
    /*font-size: 10px;*/
}
kbd {
    font: 11px "M PLUS 1 Code", monospace;
}
#sk_omnibarSearchArea .prompt, #sk_omnibarSearchArea .resultPage {
    /*font-size: 10px;*/
}
.sk_theme {
    background: #282a36;
    color: #f8f8f2;
}
.sk_theme tbody {
    color: #ff5555;
}
.sk_theme input {
    color: #ffb86c;
}
.sk_theme .url {
    color: #6272a4;
}
#sk_omnibarSearchResult>ul>li {
    background: #282a36;
}
#sk_omnibarSearchResult ul li:nth-child(odd) {
    background: #282a36;
}
.sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) {
    background: #282a36;
}
.sk_theme .annotation {
    color: #6272a4;
}
.sk_theme .focused {
    background: #44475a !important;
}
.sk_theme kbd {
    background: #f8f8f2;
    color: #44475a;
}
.sk_theme .frame {
    background: #8178DE9E;
}
.sk_theme .omnibar_highlight {
    color: #8be9fd;
}
.sk_theme .omnibar_folder {
    color: #ff79c6;
}
.sk_theme .omnibar_timestamp {
    color: #bd93f9;
}
.sk_theme .omnibar_visitcount {
    color: #f1fa8c;
}

.sk_theme .prompt, .sk_theme .resultPage {
    color: #50fa7b;
}
.sk_theme .feature_name {
    color: #ff5555;
}
.sk_omnibar_middle #sk_omnibarSearchArea {
    border-bottom: 1px solid #282a36;
}
#sk_status {
    border: 1px solid #282a36;
}
#sk_richKeystroke {
    background: #282a36;
    box-shadow: 0px 2px 10px rgba(40, 42, 54, 0.8);
}
#sk_richKeystroke kbd>.candidates {
    color: #ff5555;
}
#sk_keystroke {
    background-color: #282a36;
    color: #f8f8f2;
}
kbd {
    border: solid 1px #f8f8f2;
    border-bottom-color: #f8f8f2;
    box-shadow: inset 0 -1px 0 #f8f8f2;
}
#sk_frame {
    border: 4px solid #ff5555;
    background: #8178DE9E;
    box-shadow: 0px 0px 10px #DA3C0DCC;
}
#sk_banner {
    border: 1px solid #8be9fd;
    background: rgb(139, 233, 253);
}
div.sk_tabs_bg {
    background: #f8f8f2;
}
div.sk_tab {
    background: -webkit-gradient(linear, left top, left bottom, color-stop(0%,#6272a4), color-stop(100%,#44475a));
}
div.sk_tab_title {
    color: #f8f8f2;
}
div.sk_tab_url {
    color: #8be9fd;
}
div.sk_tab_hint {
    background: #cdc1ff;
    color: #282a36;
    border: solid 1px #282a36;
}
#sk_bubble {
    border: 1px solid #f8f8f2;
    color: #282a36;
    background-color: #f8f8f2;
}
#sk_bubble * {
    color: #282a36 !important;
}
div.sk_arrow[dir=down]>div:nth-of-type(1) {
    border-top: 12px solid #f8f8f2;
}
div.sk_arrow[dir=up]>div:nth-of-type(1) {
    border-bottom: 12px solid #f8f8f2;
}
div.sk_arrow[dir=down]>div:nth-of-type(2) {
    border-top: 10px solid #f8f8f2;
}
div.sk_arrow[dir=up]>div:nth-of-type(2) {
    border-bottom: 10px solid #f8f8f2;
}
/*
#sk_omnibar {
    width: 100%;
    left: 0%;
}
*/
}`;
// settings.omnibarPosition = "bottom";
settings.hintAlign = "left";

const removeAlias = [
    "d", // duckduckgo
    "e", // wikipedia
    "b", // baidu
    "w", // bing
    "s", // stackoverflow
    "h", // github
]
for (const alias of removeAlias) {
    api.removeSearchAlias(alias);
}

api.addSearchAlias("f", "GitHub", "https://github.com/search?q=", "h");

api.aceVimMap('p', "<C-S-v>", "normal")
api.aceVimMap('p', "<C-V>", "visual")
api.aceVimMap('y', '<C-c>', 'visual');

