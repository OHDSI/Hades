"use strict";

function loadJSONP(path, callbackName) {
    var head = document.getElementsByTagName('head')[0];
    var el = document.createElement('script');
    el.src = path + '&callback=' + callbackName;
    head.insertBefore(el, head.firstChild);
}

function apiCallback(results) {
    var resultDataList = results.data;
	if (resultDataList.length == 0)
		return;
	var repo = resultDataList[0].repository_url.replace(/^.*\//, "");
	var content = document.getElementById(repo);
	var repoTitle = document.createElement("h3");
	repoTitle.href = resultDataList[0].repository_url;
	repoTitle.textContent = repo;
	repoTitle.setAttribute("target", "_blank");
	
    var mileStoneList = document.createElement("ul");
	var mileStoneNumberToList = new Map();
	var mileStoneIssueList;
	var hasMilestone = false;
    for (var i = 0; i < resultDataList.length; i++) {
        var issue = resultDataList[i];
		if (issue.milestone.state == 'open') {
			if (!mileStoneNumberToList.has(issue.milestone.number)) {
				var mileStoneLi = document.createElement("li");
				var mileStoneA = document.createElement("a");
				mileStoneA.href = issue.milestone.html_url;
				mileStoneA.textContent = issue.milestone.title;
				mileStoneA.setAttribute("target", "_blank");
				mileStoneLi.appendChild(mileStoneA);
				if (issue.milestone.description !== null) {
					var mileStoneP = document.createElement("p");
					mileStoneP.textContent = issue.milestone.description;
					mileStoneLi.appendChild(mileStoneP);
				}
				
				mileStoneIssueList = document.createElement("ul");
				mileStoneLi.appendChild(mileStoneIssueList);
				mileStoneList.appendChild(mileStoneLi);
				mileStoneNumberToList.set(issue.milestone.number, mileStoneIssueList);
			} else {
				mileStoneIssueList = mileStoneNumberToList.get(issue.milestone.number);
			}
			var issueLi = document.createElement("li");
			var issueA = document.createElement("a");
			issueA.href = issue.html_url;
			issueA.textContent = issue.title;
			issueA.setAttribute("target", "_blank");
			issueLi.appendChild(issueA);
			mileStoneIssueList.appendChild(issueLi);	
			hasMilestone = true;			
		}
    }
	if (!hasMilestone)
		return;
	content.appendChild(repoTitle);
    content.appendChild(mileStoneList);
}

function addMileStones(repo) {
    var apiEndPoint = 'https://api.github.com/repos/ohdsi/'+ repo + '/issues?milestone=*&state=all';
    loadJSONP(apiEndPoint, "apiCallback");
}