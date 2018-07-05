          var simplemde = new SimpleMDE({
            autosave: {
              enabled: true,
              uniqueId: "Smeagol-{{page}}",
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
