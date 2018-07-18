/**
 * Provide SimpleMDE support for textareas on this page. TODO: this is
 * slightly problematic since it assumes (and saves autosave data for)
 * only one text area on the page. Perhaps we should disable autosave?
 */
var simplemde = new SimpleMDE({
  autosave: {
    enabled: true,
    uniqueId: "{{page}}-{{record.id}}",
    delay: 1000,
  },
  indentWithTabs: true,
  insertTexts: {
    horizontalRule: ["", "\n\n-----\n\n"],
    image: ["![](http://", ")"],
    link: ["[", "](http://)"],
    table: ["", "\n\n| Column 1 | Column 2 | Column 3 |\n| -------- | -------- | -------- |\n| Text     | Text      | Text     |\n\n"],
  },
  showIcons: ["code"], //, "table"], - sadly, markdown-clj does not support tables
  spellChecker: true,
  status: ["autosave", "lines", "words", "cursor"]
});
