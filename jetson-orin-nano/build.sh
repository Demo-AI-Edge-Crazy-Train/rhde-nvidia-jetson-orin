#!/bin/bash

set -Eeuo pipefail

KERNEL_CMDLINE="console=ttyTCU0"

for source_file in sources/*.toml; do
    composer-cli sources add "$source_file"
done

for blueprint_file in blueprints/*.toml; do
    composer-cli blueprints push "$blueprint_file"
    blueprint="$(basename "$blueprint_file" .toml)"
    echo "Processing blueprint $blueprint..."
    
    echo "Building ostree for $blueprint..."
    BUILDID=$(composer-cli compose start-ostree "$blueprint" edge-commit --url "http://$PUBLIC_IP/ostree/" --ref "rhel/9/$(uname -m)/$blueprint" --parent "rhel/9/$(uname -m)/edge" | awk '{print $2}')
    wait_for_compose "$BUILDID"
    composer-cli compose image "${BUILDID}" --filename /tmp
    mkdir -p "$OSTREE_TMP/${BUILDID}-commit"
    tar -xf "/tmp/${BUILDID}-commit.tar" -C "$OSTREE_TMP/${BUILDID}-commit"
    ostree --repo=$OSTREE_ROOT pull-local --untrusted "$OSTREE_TMP/${BUILDID}-commit/repo"
    rm -rf "/tmp/${BUILDID}-commit" "/tmp/${BUILDID}-commit.tar"
    composer-cli compose delete "${BUILDID}"

    if [ -f "kickstarts/$blueprint.cfg" ]; then
        kickstart_file="kickstarts/$blueprint.cfg"
        kickstart="$(basename "$kickstart_file" .cfg)"
        echo "Embedding kickstart $kickstart in generic edge installer..."
        ksvalidator "$kickstart_file" || echo "Kickstart has errors, please fix them!"
        rm -f "$ISO_ROOT/edge-installer-empty-ostree-with-kickstart-$kickstart.iso"
        mkksiso -r "inst.ks" -c "$KERNEL_CMDLINE" --ks "$kickstart_file" "$ISO_ROOT/edge-installer-empty-ostree.iso" "$ISO_ROOT/edge-installer-empty-ostree-with-kickstart-$kickstart.iso"
    fi

    echo "Building edge-installer for $blueprint..."
    BUILDID=$(composer-cli compose start-ostree --url "http://$PUBLIC_IP/ostree/" --ref "rhel/9/$(uname -m)/$blueprint" edge-installer edge-installer | awk '{print $2}')
    wait_for_compose "$BUILDID"
    rm -f "$ISO_ROOT/edge-installer-$blueprint.iso"
    composer-cli compose image "${BUILDID}" --filename "$ISO_ROOT/edge-installer-$blueprint.iso"
    
    if [ -f "kickstarts/$blueprint.cfg" ]; then
        echo "Embedding kickstart in edge-installer for $blueprint..."
        kickstart_file="kickstarts/$blueprint.cfg"
        kickstart="$(basename "$kickstart_file" .cfg)"
        ksvalidator "$kickstart_file" || echo "Kickstart has errors, please fix them!"
        rm -f "$ISO_ROOT/edge-installer-$blueprint-with-kickstart.iso"
        mkksiso -r "inst.ks" -c "$KERNEL_CMDLINE" --ks "$kickstart_file" "$ISO_ROOT/edge-installer-$blueprint.iso" "$ISO_ROOT/edge-installer-$blueprint-with-kickstart.iso"
    fi

    composer-cli compose delete "${BUILDID}"
done

for kickstart_file in kickstarts/*.cfg; do
    kickstart="$(basename "$kickstart_file" .cfg)"
    if [ ! -f "blueprints/$kickstart.toml" ]; then
        echo "Embedding standalone kickstart $kickstart in generic edge installer..."
        ksvalidator "$kickstart_file" || echo "Kickstart has errors, please fix them!"
        rm -f "$ISO_ROOT/edge-installer-empty-ostree-with-kickstart-$kickstart.iso"
        mkksiso -r "inst.ks" -c "$KERNEL_CMDLINE" --ks "$kickstart_file" "$ISO_ROOT/edge-installer-empty-ostree.iso" "$ISO_ROOT/edge-installer-empty-ostree-with-kickstart-$kickstart.iso"
    fi
done
