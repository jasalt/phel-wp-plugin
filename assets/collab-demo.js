(function ($, wp) {
    'use strict';

    var root = document.getElementById('phel-collab-demo');
    if (!root || !wp || !wp.heartbeat) {
        return;
    }

    var revision = Number(root.dataset.revision || 0);
    var status = document.getElementById('phel-collab-status');
    var input = document.getElementById('phel-collab-message');
    var save = document.getElementById('phel-collab-save');
    var refresh = document.getElementById('phel-collab-refresh');

    function setStatus(message) {
        if (status) {
            status.textContent = message;
        }
    }

    function replaceReactiveRegion(html) {
        if (!html) {
            return;
        }

        var current = document.getElementById('phel-collab-region');
        var template = document.createElement('template');
        template.innerHTML = html.trim();
        var next = template.content.firstElementChild;

        if (current && next) {
            current.replaceWith(next);
        }
    }

    function applyPayload(payload, source) {
        if (!payload) {
            return;
        }

        if (payload.changed) {
            replaceReactiveRegion(payload.html);
        }

        if (typeof payload.revision !== 'undefined') {
            revision = Number(payload.revision);
            root.dataset.revision = String(revision);
        }

        if (payload.changed && source === 'heartbeat') {
            setStatus('A collaborator changed shared state; region refreshed at revision ' + revision + '.');
        }
    }

    // Force the fastest allowed polling cadence while the dashboard is
    // focused.  WordPress enforces a 5-second floor for the "fast"
    // (focused) interval and a 60-second floor for the background one.
    wp.heartbeat.interval(5, 60);

    // Hyper watch -> polling dependency declaration: every Heartbeat tells the
    // server which revision this tab has already observed.
    $(document).on('heartbeat-send.phelCollab', function (event, data) {
        data.phel_collab = { revision: revision };
    });

    $(document).on('heartbeat-tick.phelCollab', function (event, data) {
        if (data && data.phel_collab) {
            applyPayload(data.phel_collab, 'heartbeat');
        }

        // Re-assert the fast interval.  WordPress resets the heartbeat
        // schedule to its own defaults after a few fast ticks; calling
        // interval() on every tick keeps the cadence pinned at 5 s.
        wp.heartbeat.interval(5, 60);
    });

    async function saveMessage() {
        var body = new URLSearchParams({
            action: 'phel_collab_mutate',
            operation: 'save-message',
            nonce: root.dataset.nonce,
            revision: String(revision),
            message: input ? input.value : ''
        });

        setStatus('Saving...');
        if (save) {
            save.disabled = true;
        }

        try {
            var response = await fetch(root.dataset.ajaxUrl, {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
                },
                body: body.toString()
            });
            var result = await response.json();

            if (result.success) {
                applyPayload(result.data, 'action');
                setStatus('Saved immediately at revision ' + revision + '. Other tabs will observe it on Heartbeat.');
                return;
            }

            if (result.data && result.data.code === 'conflict') {
                applyPayload(result.data, 'conflict');
                setStatus('Conflict: shared state changed first. Review the refreshed value before saving again.');
                return;
            }

            setStatus('Save failed: ' + ((result.data && result.data.code) || response.status));
        } catch (error) {
            setStatus('Save failed: ' + error.message);
        } finally {
            if (save) {
                save.disabled = false;
            }
        }
    }

    if (save) {
        save.addEventListener('click', saveMessage);
    }

    if (refresh) {
        refresh.addEventListener('click', function () {
            setStatus('Polling now...');
            wp.heartbeat.connectNow();
        });
    }

    wp.heartbeat.interval(5, 60);
    wp.heartbeat.connectNow();
})(window.jQuery, window.wp);
