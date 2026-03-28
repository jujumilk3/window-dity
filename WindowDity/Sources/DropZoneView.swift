import AppKit

class DropZoneView: NSView {
    private let zone: DropZone
    private let label = NSTextField(labelWithString: "")

    var isHighlighted: Bool = false {
        didSet {
            guard isHighlighted != oldValue else { return }
            animateHighlight()
        }
    }

    init(zone: DropZone) {
        self.zone = zone
        super.init(frame: .zero)
        wantsLayer = true
        setupLayer()
        setupLabel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupLayer() {
        guard let layer = layer else { return }
        layer.cornerRadius = 10
        layer.borderWidth = 2
        layer.borderColor = zone.color.withAlphaComponent(0.4).cgColor
        layer.backgroundColor = zone.color.withAlphaComponent(0.15).cgColor
    }

    private func setupLabel() {
        label.stringValue = zone.title
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.alignment = .center
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -16),
        ])
    }

    private func animateHighlight() {
        guard let layer = layer else { return }
        let fillOpacity: CGFloat = isHighlighted ? 0.35 : 0.15
        let borderOpacity: CGFloat = isHighlighted ? 0.9 : 0.4
        let borderWidth: CGFloat = isHighlighted ? 3 : 2

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.allowsImplicitAnimation = true
            layer.backgroundColor = zone.color.withAlphaComponent(fillOpacity).cgColor
            layer.borderColor = zone.color.withAlphaComponent(borderOpacity).cgColor
            layer.borderWidth = borderWidth
        }
    }
}
