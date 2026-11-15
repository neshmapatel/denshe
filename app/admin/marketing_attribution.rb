# frozen_string_literal: true

ActiveAdmin.register_page "Marketing Attribution" do
  menu priority: 3, label: "Marketing Attribution"

  content title: "Instagram & Campaign Attribution" do
    insta_visits = Ahoy::Visit.from_instagram
    all_campaigns = Ahoy::Visit.with_campaign
    attributed_orders = Order.joins(:ahoy_visit).where.not(ahoy_visits: { utm_campaign: [nil, ""] })

    panel "Instagram & Campaign Performance Overview" do
      revenue = attributed_orders.revenue_paid.sum(:total)
      ul do
        li "Instagram Visitors: #{insta_visits.count} (#{insta_visits.where("started_at >= ?", 30.days.ago).count} in last 30 days)"
        li "Campaign Visitors: #{all_campaigns.count} across #{all_campaigns.distinct.count(:utm_campaign)} unique campaigns"
        li "Attributed Orders: #{attributed_orders.count} total (#{attributed_orders.revenue_paid.count} paid)"
        li "Attributed Revenue: ₹#{revenue} directly from tracked campaigns"
      end
    end

    panel "Performance by Campaign (Which Reel / Post Sold?)" do
      campaign_groups = all_campaigns
        .group(:utm_campaign, :utm_source, :utm_medium)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(20)
        .count

      if campaign_groups.any?
        table_for campaign_groups.to_a do
          column("Campaign Name") { |(keys, _)| keys[0] }
          column("Source") { |(keys, _)| keys[1] || "—" }
          column("Medium") { |(keys, _)| keys[2] || "—" }
          column("Visits") { |(_, count)| count }
          column("Completed Orders") do |(keys, _)|
            Order.joins(:ahoy_visit).where(ahoy_visits: { utm_campaign: keys[0] }).count
          end
          column("Paid Revenue") do |(keys, _)|
            rev = Order.revenue_paid.joins(:ahoy_visit).where(ahoy_visits: { utm_campaign: keys[0] }).sum(:total)
            "₹#{rev}"
          end
          column("Conversion Rate") do |(keys, count)|
            orders_count = Order.joins(:ahoy_visit).where(ahoy_visits: { utm_campaign: keys[0] }).count
            rate = count.positive? ? ((orders_count.to_f / count) * 100).round(1) : 0
            "#{rate}%"
          end
        end
      else
        para "No campaign traffic recorded yet. Use the UTM Link Generator below when sharing links in Instagram Reels, Stories, or bio to begin tracking sales attribution."
      end
    end

    panel "Visitors & Orders by City / Region" do
      cities = Ahoy::Visit.where.not(city: [nil, ""]).group(:city, :region, :country).order(Arel.sql("COUNT(*) DESC")).limit(10).count
      if cities.any?
        table_for cities.to_a do
          column("City") { |(keys, _)| keys[0] }
          column("Region / State") { |(keys, _)| keys[1] || "—" }
          column("Country") { |(keys, _)| keys[2] || "—" }
          column("Visits") { |(_, count)| count }
          column("Orders") do |(keys, _)|
            Order.joins(:ahoy_visit).where(ahoy_visits: { city: keys[0] }).count
          end
        end
      else
        para "City data will populate automatically as visitors land on the shop via Cloudflare or geo-headers."
      end
    end

    panel "Interactive UTM Link Builder (For Bio, Reels, Stories & Local Creators)" do
      div style: "background: #0f172a !important; color: #f8fafc !important; padding: 1.5rem; border: 1px solid #334155 !important; border-radius: 8px;" do
        para "Generate a clean, trackable link for your Instagram bio, Story stickers, or local creator collaborations. When clicked, Ahoy tracks the visit and credits any resulting orders to that specific campaign.", style: "color: #cbd5e1 !important; line-height: 1.6;"

        div style: "display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 1rem; margin-top: 1rem;" do
          div do
            label "1. Destination Page:", style: "font-weight: bold; display: block; margin-bottom: 0.25rem; color: #f8fafc !important;"
            select id: "utm_target_page", style: "width: 100%; padding: 0.55rem; background: #1e293b !important; color: #f8fafc !important; border: 1px solid #475569 !important; border-radius: 6px;" do
              option "Karamsad Studio (/jewellery-in-karamsad)", value: "https://denshe.shop/jewellery-in-karamsad"
              option "Anand Delivery (/jewellery-in-anand)", value: "https://denshe.shop/jewellery-in-anand"
              option "Vidya Nagar College Edit (/jewellery-in-vidya-nagar)", value: "https://denshe.shop/jewellery-in-vidya-nagar"
              option "Full Shop Catalog (/shop)", value: "https://denshe.shop/shop"
              option "Homepage (/)", value: "https://denshe.shop/"
              Product.active.order(:name).limit(30).each do |p|
                option "Product: #{p.name} (/pieces/#{p.slug})", value: "https://denshe.shop/pieces/#{p.slug}"
              end
            end
          end

          div do
            label "2. Channel / Medium:", style: "font-weight: bold; display: block; margin-bottom: 0.25rem; color: #f8fafc !important;"
            select id: "utm_medium_select", style: "width: 100%; padding: 0.55rem; background: #1e293b !important; color: #f8fafc !important; border: 1px solid #475569 !important; border-radius: 6px;" do
              option "Instagram Reel (reels)", value: "reels"
              option "Instagram Story Sticker (story)", value: "story"
              option "Instagram Bio Link (bio)", value: "bio"
              option "Local Creator Collab (creator)", value: "creator"
              option "WhatsApp Broadcast (whatsapp)", value: "whatsapp"
            end
          end

          div do
            label "3. Campaign / Creator Name:", style: "font-weight: bold; display: block; margin-bottom: 0.25rem; color: #f8fafc !important;"
            input type: :text, id: "utm_campaign_input", placeholder: "e.g. vidyanagar_college_drop or collab_priya", style: "width: 100%; padding: 0.55rem; background: #1e293b !important; color: #f8fafc !important; border: 1px solid #475569 !important; border-radius: 6px;"
          end
        end

        div style: "margin-top: 1.25rem; background: #1e293b !important; padding: 1rem; border-radius: 6px; border: 1px solid #334155 !important;" do
          label "Generated Trackable URL:", style: "font-weight: bold; display: block; margin-bottom: 0.35rem; color: #38bdf8 !important;"
          div style: "display: flex; gap: 0.5rem;" do
            input type: :text, id: "utm_result_url", readonly: true, value: "https://denshe.shop/jewellery-in-karamsad?utm_source=instagram&utm_medium=reels&utm_campaign=karamsad_feature", style: "flex: 1; padding: 0.5rem; font-family: monospace; font-size: 0.95rem; background: #0f172a !important; color: #38bdf8 !important; border: 1px solid #475569 !important; border-radius: 4px;"
            button "Copy Link", type: :button, id: "copy_utm_button", class: "button", style: "background: #181868; color: #fff; padding: 0.5rem 1rem; border: none; border-radius: 4px; cursor: pointer; font-weight: bold;"
          end
          span id: "copy_feedback", style: "display: none; color: #4ade80 !important; font-size: 0.85rem; font-weight: bold; margin-top: 0.35rem;" do
            "✓ Copied to clipboard!"
          end
        end

        script do
          raw <<~JS
            (function() {
              function updateUtmUrl() {
                var targetEl = document.getElementById('utm_target_page');
                var mediumEl = document.getElementById('utm_medium_select');
                var campaignEl = document.getElementById('utm_campaign_input');
                var resultEl = document.getElementById('utm_result_url');
                if (!targetEl || !mediumEl || !campaignEl || !resultEl) return;

                var target = targetEl.value;
                var medium = mediumEl.value;
                var campaignRaw = campaignEl.value.trim();
                var campaign = campaignRaw.length > 0 ? campaignRaw.toLowerCase().replace(/[^a-z0-9_]/g, '_') : 'campaign';
                var source = (medium === 'whatsapp') ? 'whatsapp' : 'instagram';
                var separator = target.indexOf('?') >= 0 ? '&' : '?';
                resultEl.value = target + separator + 'utm_source=' + source + '&utm_medium=' + medium + '&utm_campaign=' + campaign;
              }

              var targetEl = document.getElementById('utm_target_page');
              var mediumEl = document.getElementById('utm_medium_select');
              var campaignEl = document.getElementById('utm_campaign_input');
              var copyBtn = document.getElementById('copy_utm_button');

              if (targetEl) targetEl.addEventListener('change', updateUtmUrl);
              if (mediumEl) mediumEl.addEventListener('change', updateUtmUrl);
              if (campaignEl) campaignEl.addEventListener('input', updateUtmUrl);

              if (copyBtn) {
                copyBtn.addEventListener('click', function() {
                  var urlInput = document.getElementById('utm_result_url');
                  if (!urlInput) return;
                  urlInput.select();
                  urlInput.setSelectionRange(0, 99999);
                  navigator.clipboard.writeText(urlInput.value).then(function() {
                    var fb = document.getElementById('copy_feedback');
                    if (fb) {
                      fb.style.display = 'inline-block';
                      setTimeout(function() { fb.style.display = 'none'; }, 2500);
                    }
                  });
                });
              }
              updateUtmUrl();
            })();
          JS
        end
      end
    end
  end
end
